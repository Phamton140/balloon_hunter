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
  final ScoreManager scoreManager = ScoreManager();
  final LevelManager levelManager = LevelManager();
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
    // 1. Inicializar componentes asíncronos de los gestores
    await audioManager.initialize();
    await saveManager.initialize();
    
    // Iniciar de forma asíncrona sin bloquear la pantalla de carga principal
    // porque pueden tardar mucho o fallar si no hay internet
    rankingManager.initialize();
    cloudSyncManager.initialize();
    authManager.initialize(saveManager);
    
    // Configurar observador del ciclo de vida para Flame
    // No necesitamos LifecycleListener porque la app principal lo maneja

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
    final maxLevel = gameManager.saveManager.maxLevelReached;

    // ¿Globo negro especial?
    if (enemyDirector.shouldSpawnBlackBalloon(config, maxLevel)) {
      _spawnSpecialBalloon(BalloonType.black);
      return;
    }

    // ¿Globo azul especial?
    if (enemyDirector.shouldSpawnBlueBalloon(config, maxLevel)) {
      _spawnSpecialBalloon(BalloonType.blue);
      // También puede aparecer un globo normal en el mismo ciclo
    }

    // ¿Globo reloj especial?
    if (enemyDirector.shouldSpawnClockBalloon(config, maxLevel)) {
      _spawnSpecialBalloon(BalloonType.clock);
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
    final config = levelManager.config;
    final maxLevel = gameManager.saveManager.maxLevelReached;

    // ¿Globo blindado?
    if (enemyDirector.shouldSpawnArmoredBalloon(config, maxLevel)) {
      final balloon = spawnManager.spawnArmoredBalloon();
      balloon.onTapped = _onArmoredBalloonTapped;
      balloon.onEscaped = _onArmoredBalloonEscaped;
      return; // Los blindados reemplazan un spawn normal para no saturar la pantalla
    }

    // ¿Globo normal?
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

  void _onArmoredBalloonTapped(ArmoredBalloonComponent armored) {
    if (gameManager.state != GameState.playing) return;
    
    // Reproducir un sonido metálico. Se puede simular bajando el pitch o usando playHit
    // Como aún no tenemos un audio especial, usamos playPopBlack o uno genérico:
    // Idealmente: audioManager.playMetalHit();
    // Por ahora reusaremos popBlack para el daño
    
    armored.takeHit();
    
    if (armored.hp <= 0) {
      // Explotó
      audioManager.playPopRed(); // Sonido estándar de explosión de globo
      spawnManager.spawnExplosion(armored.position, type: armored.balloonType);
      
      collisionManager.handleBalloonTap(armored.balloonType);
      
      add(FloatingTextComponent(
          text: '+10',
          position: armored.position.clone(),
          color: Colors.white,
      ));
      
      armored.explodeAndReturn();
    } else {
      // Solo recibió daño
      audioManager.playPopBlack(); // Simularemos el golpe duro con este sonido por ahora
      // Se podría añadir texto de "+Daño" flotante si se desea
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
      } else if (type == BalloonType.clock) {
        audioManager.playLevelUp(); // Usaremos este sonido que da sensación de premio
        gameManager.activateClockBalloon();
        
        // Mostrar animación de texto flotante en el centro de la pantalla
        add(FloatingTextComponent(
          text: '-10s',
          position: Vector2(size.x / 2, size.y / 2),
          color: Colors.orangeAccent,
        ));
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
