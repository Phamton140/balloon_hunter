// lib/balloon_hunter_game.dart
// FlameGame principal: orquesta todos los componentes y gestores

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'components/background_component.dart';
import 'components/balloon_component.dart';
import 'components/bird_component.dart';
import 'components/special_balloon_component.dart';
import 'components/armored_balloon_component.dart';
import 'components/explosion_component.dart';
import 'components/floating_text_component.dart';
import 'components/ice_effect_component.dart';
import 'managers/auth_manager.dart';
import 'managers/friends_manager.dart';
import 'managers/inbox_manager.dart';
import 'managers/audio_manager.dart';
import 'managers/collision_manager.dart';
import 'managers/enemy_director.dart';
import 'managers/event_manager.dart';
import 'managers/game_manager.dart';
import 'managers/level_manager.dart';
import 'managers/ranking_manager.dart';
import 'managers/score_manager.dart';
import 'managers/save_manager.dart';
import 'managers/spawn_manager.dart';
import 'managers/timer_manager.dart';
import 'models/balloon_type.dart';
import 'models/game_event.dart';
import 'models/game_state.dart';
import 'utils/constants.dart';

import 'managers/cloud_sync_manager.dart';

/// FlameGame principal de Balloon Hunter.
/// Gestiona el game loop, los overlays y coordina todos los subsistemas.
class BalloonHunterGame extends FlameGame with TapCallbacks {
  // -- Gestores --
  final AudioManager audioManager = AudioManager();
  final LevelManager levelManager = LevelManager();
  late final ScoreManager scoreManager;
  final TimerManager timerManager = TimerManager();
  final AuthManager authManager = AuthManager();
  late final FriendsManager friendsManager;
  late final InboxManager inboxManager;
  late final RankingManager rankingManager;
  final EventManager eventManager = EventManager();
  final CollisionManager collisionManager = CollisionManager();
  final EnemyDirector enemyDirector = EnemyDirector();
  final SpawnManager spawnManager = SpawnManager();
  final SaveManager saveManager = SaveManager();
  final CloudSyncManager cloudSyncManager = CloudSyncManager();
  late final GameManager gameManager;
  late final BackgroundComponent background;

  // -- Estado de spawn --
  double _spawnTimer = 0.0;
  bool _gameOverTriggered = false;
  bool _birdHitGameOver = false;

  BalloonHunterGame() {
    scoreManager = ScoreManager(levelManager);
    inboxManager = InboxManager(authManager);
    friendsManager = FriendsManager(authManager, inboxManager);
    rankingManager = RankingManager(authManager);
    
    gameManager = GameManager(
      audioManager: audioManager,
      scoreManager: scoreManager,
      levelManager: levelManager,
      timerManager: timerManager,
      rankingManager: rankingManager,
      eventManager: eventManager,
      saveManager: saveManager,
      cloudSyncManager: cloudSyncManager,
      authManager: authManager,
      friendsManager: friendsManager,
      inboxManager: inboxManager,
    );
  }

  @override
  Future<void> onLoad() async {
    await audioManager.initialize();
    await gameManager.initialize();
    await cloudSyncManager.initialize();

    spawnManager.initialize(
      addToGame: add,
      getScreenWidth: () => size.x,
      getScreenHeight: () => size.y,
    );

    _setupCollisionCallbacks();

    gameManager.onGameOver = _onGameOverCallback;
    gameManager.onLevelComplete = _onLevelCompleteCallback;
    gameManager.onBlackBalloonActivated = _onBlackBalloonActivated;

    _setupEventHandlers();

    background = BackgroundComponent();
    add(background);

    if (gameManager.state == GameState.registration) {
      overlays.add(GameConstants.overlayRegistration);
    } else {
      overlays.add(GameConstants.overlayMainMenu);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameManager.state != GameState.playing || gameManager.isFrozen) return;

    timerManager.update(dt);
    gameManager.update(dt);
    enemyDirector.update(dt);

    if (timerManager.isTimeUp && !_gameOverTriggered) {
      _onLevelTimeUp();
      return;
    }

    _spawnTimer += dt;
    final spawnDelay = enemyDirector.nextSpawnDelay(levelManager.config);

    if (_spawnTimer >= spawnDelay) {
      _spawnTimer = 0.0;
      _handleSpawn();
    }
  }

  void _handleSpawn() {
    final config = levelManager.config;
    final maxLevel = gameManager.saveManager.maxLevelReached;

    if (enemyDirector.shouldSpawnBlackBalloon(config, maxLevel)) {
      _spawnSpecialBalloon(BalloonType.black);
      return;
    }

    if (enemyDirector.shouldSpawnBlueBalloon(config, maxLevel)) {
      _spawnSpecialBalloon(BalloonType.blue);
    }

    if (enemyDirector.shouldSpawnClockBalloon(config, maxLevel)) {
      _spawnSpecialBalloon(BalloonType.clock);
    }

    if (enemyDirector.shouldSpawnBird(config)) {
      _spawnBird();
    } else {
      _spawnNormalBalloon();
    }
  }

  void _spawnNormalBalloon() {
    final config = levelManager.config;
    final maxLevel = gameManager.saveManager.maxLevelReached;

    if (enemyDirector.shouldSpawnArmoredBalloon(config, maxLevel)) {
      final armoredBalloon = spawnManager.spawnArmoredBalloon();
      armoredBalloon.onTapped = _onArmoredBalloonTapped;
      armoredBalloon.onEscaped = _onArmoredBalloonEscaped;
      return; 
    }

    final type = enemyDirector.selectBalloonType(levelManager.config);
    final balloon = spawnManager.spawnBalloon(type);
    balloon.onTapped = _onBalloonTapped;
    balloon.onEscaped = _onBalloonEscaped;

    if (gameManager.slowMultiplier < 1.0) {
      balloon.applySlowMultiplier(gameManager.slowMultiplier);
    }
  }

  void _spawnBird() {
    final bird = spawnManager.spawnBird();
    bird.onTapped = _onBirdTapped;
  }

  void _spawnSpecialBalloon(BalloonType type) {
    final special = spawnManager.spawnSpecialBalloon(type);
    special.onTapped = _onSpecialBalloonTapped;
  }

  // ==========================================================================
  // CALLBACKS DE TOQUE (POSICIONAMIENTO CORREGIDO MEDIANTE .clone())
  // ==========================================================================

  void _onBalloonTapped(BalloonComponent balloon) {
    if (gameManager.state != GameState.playing) return;

    // Clonar la posición antes de liberar el componente al pool
    final targetPosition = balloon.position.clone();

    balloon.explodeAndReturn();
    spawnManager.spawnExplosion(targetPosition, type: balloon.balloonType);

    if (balloon.balloonType == BalloonType.black) {
      audioManager.playPopBlack();
      _triggerVibration(strong: true);
      gameManager.activateBlackBalloon();
    } else {
      collisionManager.handleBalloonTap(balloon.balloonType);
    }
  }

  void _onBirdTapped(BirdComponent bird) {
    if (gameManager.state != GameState.playing) return;

    _birdHitGameOver = true;
    final targetPosition = bird.position.clone();
    
    bird.removeFromParent(); // o return to pool según corresponda
    spawnManager.spawnExplosion(targetPosition, type: BalloonType.red);
    collisionManager.handleBirdTap();
  }

  void _onBalloonEscaped(BalloonComponent balloon) {
    if (gameManager.state != GameState.playing) return;

    levelManager.onBalloonEscaped();

    if (levelManager.isGameOver) {
      _birdHitGameOver = false;
      gameManager.triggerGameOver();
    }
  }

  void _onArmoredBalloonTapped(ArmoredBalloonComponent armored) {
    if (gameManager.state != GameState.playing) return;
    
    armored.takeHit();
    
    if (armored.hp <= 0) {
      final targetPosition = armored.position.clone();
      
      audioManager.playPopRed();
      spawnManager.spawnExplosion(targetPosition, type: armored.balloonType);
      
      collisionManager.handleBalloonTap(armored.balloonType);
      
      add(FloatingTextComponent(
        text: '+10',
        position: targetPosition,
        color: Colors.white,
      ));
      
      armored.explodeAndReturn();
    } else {
      audioManager.playPopBlack();
    }
  }

  void _onArmoredBalloonEscaped(ArmoredBalloonComponent armored) {
    if (gameManager.state != GameState.playing) return;
    levelManager.onBalloonEscaped();
    if (levelManager.isGameOver) {
      _birdHitGameOver = false;
      gameManager.triggerGameOver();
    }
  }

  void _onSpecialBalloonTapped(SpecialBalloonComponent special) {
    if (gameManager.state != GameState.playing) return;

    final targetPosition = special.position.clone();
    special.removeFromParent();

    spawnManager.spawnExplosion(targetPosition, type: special.specialType);
    collisionManager.handleSpecialBalloonTap(special.specialType);
  }

  void _setupCollisionCallbacks() {
    collisionManager.onBalloonHit = (BalloonType type) {
      scoreManager.addPoints(type.points);
      _playBalloonSound(type);
      _triggerVibration();
    };

    collisionManager.onBirdHit = () {
      audioManager.playBirdHit();
      _triggerVibration(strong: true);
      gameManager.triggerGameOver();
    };

    collisionManager.onSpecialBalloonHit = (BalloonType type) {
      if (type == BalloonType.blue) {
        audioManager.playPopBlue();
        gameManager.activateSlowMotion();
        add(IceEffectComponent());
      } else if (type == BalloonType.black) {
        audioManager.playPopBlack();
        gameManager.activateBlackBalloon();
      } else if (type == BalloonType.clock) {
        audioManager.playLevelUp();
        gameManager.activateClockBalloon();
        
        add(FloatingTextComponent(
          text: '-10s',
          position: Vector2(size.x / 2, size.y / 2),
          color: Colors.orangeAccent,
        ));
      }
    };

    collisionManager.onMiss = () {
      scoreManager.registerMiss();
    };
  }

  void _setupEventHandlers() {
    eventManager.register(GameEventType.slowMotionStart, (event) {
      for (final b in children.whereType<BalloonComponent>()) {
        b.applySlowMultiplier(0.5);
      }
      for (final bird in children.whereType<BirdComponent>()) {
        bird.applySlowMultiplier(0.5);
      }
    });

    eventManager.register(GameEventType.slowMotionEnd, (event) {
      for (final b in children.whereType<BalloonComponent>()) {
        b.applySlowMultiplier(1.0);
      }
      for (final bird in children.whereType<BirdComponent>()) {
        bird.applySlowMultiplier(1.0);
      }
    });

    eventManager.register(GameEventType.blackBalloonExplosion, (event) {});
  }

  void _onGameOverCallback() {
    _gameOverTriggered = true;
    overlays.remove(GameConstants.overlayHud);
    overlays.add(GameConstants.overlayGameOver);
  }

  void _onLevelCompleteCallback() {
    overlays.remove(GameConstants.overlayHud);
    overlays.add(GameConstants.overlayVictory);
  }

  void _onBlackBalloonActivated() {
    int totalPoints = 0;
    int destroyedCount = 0;

    final balloons = spawnManager.removeAllNormalBalloons(children.toList());
    for (final b in balloons) {
      totalPoints += b.balloonType.points;
      destroyedCount++;
      // Crear animación individual de explosión en la posición de cada globo eliminado por la bomba
      spawnManager.spawnExplosion(b.position.clone(), type: b.balloonType);
    }

    final armoredBalloons = children.whereType<ArmoredBalloonComponent>().toList();
    for (final armored in armoredBalloons) {
      armored.takeHit();

      if (armored.hp <= 0) {
        totalPoints += armored.balloonType.points;
        destroyedCount++;
        spawnManager.spawnExplosion(armored.position.clone(), type: armored.balloonType);
        armored.explodeAndReturn();
      }
    }

    if (totalPoints > 0) {
      scoreManager.addBulkPoints(totalPoints, destroyedCount);
    }
  }

  void _onLevelTimeUp() {
    _gameOverTriggered = true;
    if (levelManager.isGameOver) {
      gameManager.triggerGameOver();
    } else {
      gameManager.triggerLevelComplete();
    }
  }

  Future<void> startGame() async {
    _gameOverTriggered = false;
    _birdHitGameOver = false;
    _spawnTimer = 0.0;
    enemyDirector.reset();
    spawnManager.reset();
    _clearGameComponents();
  }

  void pauseGame() {}

  void resumeGame() {}

  void goToMenu() {
    _gameOverTriggered = false;
    _clearGameComponents();
  }

  void _clearGameComponents() {
    children.whereType<BalloonComponent>().toList().forEach((c) => c.removeFromParent());
    children.whereType<BirdComponent>().toList().forEach((c) => c.removeFromParent());
    children.whereType<SpecialBalloonComponent>().toList().forEach((c) => c.removeFromParent());
    children.whereType<ArmoredBalloonComponent>().toList().forEach((c) => c.removeFromParent());
    children.whereType<ExplosionComponent>().toList().forEach((c) => c.removeFromParent());
    children.whereType<IceEffectComponent>().toList().forEach((c) => c.removeFromParent());
  }

  void _playBalloonSound(BalloonType type) {
    switch (type) {
      case BalloonType.yellow:
        audioManager.playPopYellow();
        break;
      case BalloonType.green:
        audioManager.playPopGreen();
        break;
      case BalloonType.red:
        audioManager.playPopRed();
        break;
      case BalloonType.black:
        audioManager.playPopBlack();
        break;
      default:
        break;
    }
  }

  void _triggerVibration({bool strong = false}) {
    if (strong) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    if (!event.handled && gameManager.state == GameState.playing) {
      collisionManager.handleMiss();
    }
  }
}