// lib/balloon_hunter_game.dart
// FlameGame principal: orquesta todos los componentes y gestores

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart' hide Timer;
import 'components/background_component.dart';
import 'components/balloon_component.dart';
import 'components/bird_component.dart';
import 'components/special_balloon_component.dart';
import 'components/explosion_component.dart';
import 'components/ice_effect_component.dart';
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

/// FlameGame principal de Balloon Hunter.
/// Gestiona el game loop, los overlays y coordina todos los subsistemas.
class BalloonHunterGame extends FlameGame with TapCallbacks {
  // -- Gestores --
  final AudioManager audioManager = AudioManager();
  final ScoreManager scoreManager = ScoreManager();
  final LevelManager levelManager = LevelManager();
  final TimerManager timerManager = TimerManager();
  final RankingManager rankingManager = RankingManager();
  final EventManager eventManager = EventManager();
  final CollisionManager collisionManager = CollisionManager();
  final EnemyDirector enemyDirector = EnemyDirector();
  final SpawnManager spawnManager = SpawnManager();
  final SaveManager saveManager = SaveManager();
  late final GameManager gameManager;
  late final BackgroundComponent background;

  // -- Estado de spawn --
  double _spawnTimer = 0.0;
  bool _gameOverTriggered = false;
  bool _birdHitGameOver = false;

  BalloonHunterGame() {
    gameManager = GameManager(
      audioManager: audioManager,
      scoreManager: scoreManager,
      levelManager: levelManager,
      timerManager: timerManager,
      rankingManager: rankingManager,
      eventManager: eventManager,
      saveManager: saveManager,
    );
  }

  @override
  Future<void> onLoad() async {
    // 1. Inicializar componentes asíncronos de los gestores
    await audioManager.initialize();
    await rankingManager.initialize();
    await saveManager.initialize();

    // 2. Inicializar SpawnManager con pools
    spawnManager.initialize(
      addToGame: add,
      getScreenWidth: () => size.x,
      getScreenHeight: () => size.y,
    );

    // 3. Registrar callbacks de colisión
    _setupCollisionCallbacks();

    // 4. Registrar callbacks del GameManager
    gameManager.onGameOver = _onGameOverCallback;
    gameManager.onLevelComplete = _onLevelCompleteCallback;
    gameManager.onBlackBalloonActivated = _onBlackBalloonActivated;

    // 5. Registrar event handlers
    _setupEventHandlers();

    // 6. Añadir fondo
    background = BackgroundComponent();
    add(background);

    // 7. Mostrar menú principal
    overlays.add(GameConstants.overlayMainMenu);
  }

  // ==========================================================================
  // GAME LOOP
  // ==========================================================================

  @override
  void update(double dt) {
    // Es vital llamar a super.update SIEMPRE para que Flame procese el ciclo
    // de vida de los componentes, añada hijos y procese animaciones.
    super.update(dt);

    if (gameManager.state != GameState.playing || gameManager.isFrozen) return;

    // Actualizar gestores de tiempo
    timerManager.update(dt);
    gameManager.update(dt);
    enemyDirector.update(dt);

    // Verificar tiempo agotado
    if (timerManager.isTimeUp && !_gameOverTriggered) {
      _onLevelTimeUp();
      return;
    }

    // Ciclo de spawn
    _spawnTimer += dt;
    final spawnDelay = enemyDirector.nextSpawnDelay(levelManager.config);

    if (_spawnTimer >= spawnDelay) {
      _spawnTimer = 0.0;
      _handleSpawn();
    }

    // Actualizar velocidad de globos si hay slow motion activo
    // (los globos aplican slowMultiplier en su configure(), no en runtime)
  }

  // ==========================================================================
  // SPAWN
  // ==========================================================================

  void _handleSpawn() {
    final config = levelManager.config;

    // ¿Globo negro especial?
    if (enemyDirector.shouldSpawnBlackBalloon(config)) {
      _spawnSpecialBalloon(BalloonType.black);
      return;
    }

    // ¿Globo azul especial?
    if (enemyDirector.shouldSpawnBlueBalloon(config)) {
      _spawnSpecialBalloon(BalloonType.blue);
      // También puede aparecer un globo normal en el mismo ciclo
    }

    // ¿Ave?
    if (enemyDirector.shouldSpawnBird(config)) {
      _spawnBird();
    } else {
      // Globo normal
      _spawnNormalBalloon();
    }
  }

  void _spawnNormalBalloon() {
    final type = enemyDirector.selectBalloonType(levelManager.config);
    final balloon = spawnManager.spawnBalloon(type);
    balloon.onTapped = _onBalloonTapped;
    balloon.onEscaped = _onBalloonEscaped;

    // Apply slow motion post-configure if active
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
  // CALLBACKS DE TOQUE
  // ==========================================================================

  void _onBalloonTapped(BalloonComponent balloon) {
    if (gameManager.state != GameState.playing) return;

    balloon.explodeAndReturn();
    spawnManager.spawnExplosion(balloon.position, type: balloon.balloonType);
    collisionManager.handleBalloonTap(balloon.balloonType);
  }

  void _onBirdTapped(BirdComponent bird) {
    if (gameManager.state != GameState.playing) return;

    _birdHitGameOver = true;
    spawnManager.spawnExplosion(bird.position, type: BalloonType.red);
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

  void _onSpecialBalloonTapped(SpecialBalloonComponent special) {
    if (gameManager.state != GameState.playing) return;

    spawnManager.spawnExplosion(special.position, type: special.specialType);
    collisionManager.handleSpecialBalloonTap(special.specialType);
  }

  // ==========================================================================
  // SETUP DE CALLBACKS
  // ==========================================================================

  void _setupCollisionCallbacks() {
    // Globo normal explotado
    collisionManager.onBalloonHit = (BalloonType type) {
      scoreManager.addPoints(type.points);
      _playBalloonSound(type);
      _triggerVibration();
    };

    // Ave tocada → GAME OVER
    collisionManager.onBirdHit = () {
      audioManager.playBirdHit();
      _triggerVibration(strong: true);
      gameManager.triggerGameOver();
    };

    // Globo especial tocado
    collisionManager.onSpecialBalloonHit = (BalloonType type) {
      if (type == BalloonType.blue) {
        audioManager.playPopBlue();
        gameManager.activateSlowMotion();
        add(IceEffectComponent());
      } else if (type == BalloonType.black) {
        audioManager.playPopBlack();
        gameManager.activateBlackBalloon();
      }
    };

    // Miss (tap en zona vacía) - no se usa directamente, los taps se consumen por componentes
    collisionManager.onMiss = () {
      scoreManager.registerMiss();
    };
  }

  void _setupEventHandlers() {
    // Slow motion start
    eventManager.register(GameEventType.slowMotionStart, (event) {
      debugPrint('[Game] Slow motion started');
      for (final b in children.whereType<BalloonComponent>()) {
        b.applySlowMultiplier(0.5);
      }
      for (final bird in children.whereType<BirdComponent>()) {
        bird.applySlowMultiplier(0.5);
      }
    });

    // Slow motion end
    eventManager.register(GameEventType.slowMotionEnd, (event) {
      debugPrint('[Game] Slow motion ended');
      for (final b in children.whereType<BalloonComponent>()) {
        b.applySlowMultiplier(1.0);
      }
      for (final bird in children.whereType<BirdComponent>()) {
        bird.applySlowMultiplier(1.0);
      }
    });

    // Globo negro
    eventManager.register(GameEventType.blackBalloonExplosion, (event) {
      // La lógica real se maneja en _onBlackBalloonActivated
    });
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
    // Destruir todos los globos normales y sumar sus puntos
    final balloons = spawnManager.removeAllNormalBalloons(children.toList());
    int totalPoints = 0;
    for (final b in balloons) {
      totalPoints += b.balloonType.points;
    }
    if (totalPoints > 0) {
      scoreManager.addBulkPoints(totalPoints, balloons.length);
    }
    
    // Y limpiar las aves de la pantalla sin sumar puntos
    // spawnManager.removeAllBirds(children.toList()); // MODIFICADO: Ahora preserva aves por el medio ambiente
  }

  // ==========================================================================
  // TRANSICIONES DE ESTADO
  // ==========================================================================

  void _onLevelTimeUp() {
    _gameOverTriggered = true;
    if (levelManager.isGameOver) {
      gameManager.triggerGameOver();
    } else {
      gameManager.triggerLevelComplete();
    }
  }

  /// Inicia una nueva partida — llamado desde las pantallas
  Future<void> startGame() async {
    _gameOverTriggered = false;
    _birdHitGameOver = false;
    _spawnTimer = 0.0;
    enemyDirector.reset();
    spawnManager.reset();

    // Limpiar componentes del juego anterior (no el fondo)
    _clearGameComponents();
  }

  /// Pausa el juego
  void pauseGame() {
    // Overlays are managed by GameManager state in main.dart
  }

  /// Reanuda el juego
  void resumeGame() {
    // Overlays are managed by GameManager state in main.dart
  }

  /// Vuelve al menú
  void goToMenu() {
    _gameOverTriggered = false;
    _clearGameComponents();
  }

  void _clearGameComponents() {
    children
        .whereType<BalloonComponent>()
        .toList()
        .forEach((c) => c.removeFromParent());
    children
        .whereType<BirdComponent>()
        .toList()
        .forEach((c) => c.removeFromParent());
    children
        .whereType<SpecialBalloonComponent>()
        .toList()
        .forEach((c) => c.removeFromParent());
    children
        .whereType<ExplosionComponent>()
        .toList()
        .forEach((c) => c.removeFromParent());
    children
        .whereType<IceEffectComponent>()
        .toList()
        .forEach((c) => c.removeFromParent());
  }

  // ==========================================================================
  // AUDIO Y FEEDBACK
  // ==========================================================================

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

  // ==========================================================================
  // TAPS EN ZONA VACÍA (miss)
  // ==========================================================================

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    if (!event.handled && gameManager.state == GameState.playing) {
      collisionManager.handleMiss();
    }
  }
}
