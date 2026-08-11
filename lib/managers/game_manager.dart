// lib/managers/game_manager.dart
// Estado global y coordinación central del juego

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import '../models/game_state.dart';
import '../models/game_event.dart';
import 'audio_manager.dart';
import 'score_manager.dart';
import 'level_manager.dart';
import 'timer_manager.dart';
import 'ranking_manager.dart';
import 'event_manager.dart';
import 'save_manager.dart';
import 'auth_manager.dart';
import 'friends_manager.dart';
import 'cloud_sync_manager.dart';
import 'inbox_manager.dart';
import '../models/score_record.dart';

class SyncConflictData {
  final int localMaxLevel;
  final int localBestScore;
  final int cloudMaxLevel;
  final int cloudBestScore;
  final Map<String, dynamic>? localRecordMap;
  final Map<String, dynamic>? cloudRecordMap;

  SyncConflictData({
    required this.localMaxLevel,
    required this.localBestScore,
    required this.cloudMaxLevel,
    required this.cloudBestScore,
    this.localRecordMap,
    this.cloudRecordMap,
  });
}

enum SyncChoice { local, cloud }

/// Gestor central que coordina todos los subsistemas del juego.
/// Mantiene el estado global y la lógica de transición entre pantallas.
class GameManager extends ChangeNotifier with WidgetsBindingObserver {
  GameManager({
    required this.audioManager,
    required this.scoreManager,
    required this.levelManager,
    required this.timerManager,
    required this.rankingManager,
    required this.eventManager,
    required this.saveManager,
    required this.cloudSyncManager,
    required this.authManager,
    required this.friendsManager,
    required this.inboxManager,
  }) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || 
        state == AppLifecycleState.inactive || 
        state == AppLifecycleState.hidden) {
      
      // El usuario salió de la app o recibió una llamada
      audioManager.pauseBgm();
      
      if (_state == GameState.playing) {
        pauseGame(); // Pausa automáticamente el juego para que no pierda
      }
    } else if (state == AppLifecycleState.resumed) {
      // El usuario volvió a la app
      // Solo reanudamos la música si estamos en el menú o si el juego no está en una pantalla donde debería estar silenciado
      if (_state == GameState.mainMenu || _state == GameState.countdown || _state == GameState.playing) {
        audioManager.resumeBgm();
      }
    }
  }

  final AudioManager audioManager;
  final ScoreManager scoreManager;
  final LevelManager levelManager;
  final TimerManager timerManager;
  final RankingManager rankingManager;
  final EventManager eventManager;
  final SaveManager saveManager;
  final CloudSyncManager cloudSyncManager;
  final AuthManager authManager;
  final FriendsManager friendsManager;
  final InboxManager inboxManager;

  // -- Estado transitorio --
  GameState _state = GameState.mainMenu;
  GameState get state => _state;

  bool _isFrozen = false;
  bool get isFrozen => _isFrozen;
  
  /// Indica si hay una partida guardada en disco o en progreso
  bool get hasSavedGame => saveManager.hasSavedGame;

  // Slow motion (activado por globo azul)
  bool slowMotionActive = false;
  double slowMultiplier = 1.0;
  double _slowTimer = 0.0;
  final double _slowDuration = 5.0;
  double _playTimeAccumulator = 0.0;

  // Callbacks hacia el FlameGame
  VoidCallback? onGameOver;
  VoidCallback? onLevelComplete;
  VoidCallback? onBlackBalloonActivated;

  /// Inicializa todos los gestores
  Future<void> initialize() async {
    await saveManager.initialize();
    await rankingManager.initialize();
    await authManager.initialize(saveManager);
    
    if (authManager.isLoggedIn) {
      authManager.updateLastActive();
      await rankingManager.fetchGlobalRanking();
    }
    
    await rankingManager.syncPlayGamesScore(saveManager);
    if (!saveManager.hasRegistered) {
      _state = GameState.registration;
    } else {
      _state = GameState.mainMenu;
    }
    notifyListeners();
  }

  /// Fuerza una actualización de la UI
  void forceUpdate() {
    notifyListeners();
  }

  /// Cambia al estado indicado y notifica a la UI
  void changeState(GameState newState) {
    if (_state == newState) return;
    debugPrint('[GameManager] State: $_state → $newState');
    _state = newState;
    notifyListeners();
  }

  /// Inicia una nueva partida desde el nivel 1
  Future<void> startNewGame() async {
    await saveManager.clearSave();
    scoreManager.reset();
    scoreManager.saveLevelStartScore(); // Guarda score inicial = 0
    levelManager.reset();
    timerManager.reset();
    timerManager.start();
    _playTimeAccumulator = 0.0;
    _deactivateSlowMotion();
    changeState(GameState.countdown);
    await audioManager.playBgm();
  }

  /// Borra todo el progreso del juego (local y nube) para realizar pruebas,
  /// manteniendo la sesión del usuario intacta.
  Future<void> wipeGameData() async {
    // 1. Borrar progreso local (nivel, max score, etc)
    await saveManager.wipeProgress();
    
    // 2. Restablecer gestores en memoria
    levelManager.reset();
    scoreManager.reset();
    
    // 3. Borrar de la base de datos (leaderboard) y reiniciar nube
    if (authManager.isLoggedIn) {
      try {
        await FirebaseFirestore.instance
            .collection('leaderboard')
            .doc(authManager.playerId)
            .delete();
        await cloudSyncManager.syncMaxLevel(1);
      } catch (e) {
        debugPrint('[GameManager] Error wiping cloud data: $e');
      }
    }
    
    // 4. Refrescar UI
    rankingManager.clearLocalRecord();
    await rankingManager.fetchGlobalRanking();
    notifyListeners();
  }

  /// Continúa una partida desde el nivel guardado
  Future<void> continueSavedGame() async {
    if (!saveManager.hasSavedGame) {
      await startNewGame();
      return;
    }
    
    // Carga los datos guardados
    levelManager.loadFromSave(saveManager.savedLevel);
    scoreManager.loadFromSave(saveManager.savedScore);
    scoreManager.saveLevelStartScore(); // Guarda score inicial = cargado
    
    // Inicia el nivel como nuevo
    timerManager.reset();
    timerManager.start();
    _deactivateSlowMotion();
    changeState(GameState.countdown);
    await audioManager.playBgm();
  }

  /// Inicia el siguiente nivel
  Future<void> startNextLevel() async {
    levelManager.advanceLevel();
    scoreManager.saveLevelStartScore(); // Guarda score inicial para el nuevo nivel
    timerManager.reset();
    timerManager.start();
    _deactivateSlowMotion();
    changeState(GameState.countdown); // Cambia el estado primero para fluidez visual

    // Guarda el progreso de manera persistente en segundo plano
    await saveManager.saveGame(
      level: levelManager.currentLevel, 
      score: scoreManager.score,
    );
    // Sincronizar con la nube en segundo plano
    cloudSyncManager.syncMaxLevel(saveManager.maxLevelReached);
  }

  /// Pausa el juego
  Future<void> pauseGame() async {
    if (_state != GameState.playing) return;
    timerManager.pause();
    changeState(GameState.paused);
  }

  /// Reanuda el juego
  Future<void> resumeGame() async {
    if (_state != GameState.paused) return;
    timerManager.start();
    changeState(GameState.playing);
    await audioManager.resumeBgm();
  }

  /// Llama al iniciar un nivel completado
  Future<void> triggerLevelComplete() async {
    timerManager.pause();
    changeState(GameState.victory); // Mover el cambio de estado antes de las operaciones de red
    
    // Reproducir sonido inmediatamente
    audioManager.playLevelUp();
    onLevelComplete?.call();

    // Guarda el progreso de manera persistente al completar un nivel en segundo plano
    await saveManager.saveGame(
      level: levelManager.currentLevel + 1,
      score: scoreManager.score,
    );
    
    // Sincronizar con la nube en segundo plano
    cloudSyncManager.syncMaxLevel(saveManager.maxLevelReached);
  }

  /// Congela el juego sin cambiar el estado a gameOver (para animaciones)
  void freezeForGameOver() {
    _isFrozen = true;
    timerManager.pause();
    notifyListeners();
  }

  /// Dispara el Game Over inmediatamente
  Future<void> triggerGameOver() async {
    _isFrozen = false;
    slowMotionActive = false;
    timerManager.pause();
    
    changeState(GameState.gameOver); // Detener el juego visualmente de inmediato
    
    audioManager.stopBgm();
    onGameOver?.call();

    // Guardar puntuación y limpiar progreso en segundo plano
    await _saveScore(); // Guarda en el ranking Top 3
    await saveManager.clearSave(); // Borra el progreso del nivel actual
  }

  /// Revive al jugador tras ver un video (reinicia timer y escapes, revierte puntos)
  Future<void> reviveLevel() async {
    // Restaurar puntuación inicial del nivel (pierde lo ganado antes de morir)
    scoreManager.revertToLevelStartScore();
    // Reiniciar globos escapados
    levelManager.resetEscapes();
    // Reiniciar tiempo
    timerManager.reset();
    
    _deactivateSlowMotion();
    
    // Cambiar a reviveReady para esperar que el jugador esté listo
    changeState(GameState.reviveReady);
  }

  /// Inicia el countdown después de estar en reviveReady
  Future<void> startReviveCountdown() async {
    timerManager.start();
    changeState(GameState.countdown);
    await audioManager.playBgm();
  }

  /// Activa el efecto de slow motion (globo azul)
  void activateSlowMotion() {
    slowMotionActive = true;
    slowMultiplier = 0.5;
    _slowTimer = 0.0;
    eventManager.trigger(GameEventType.slowMotionStart, duration: _slowDuration);
    notifyListeners();
    debugPrint('[GameManager] Slow motion activated');
  }

  /// Activa el globo negro (destruye todos los globos normales)
  void activateBlackBalloon() {
    eventManager.trigger(GameEventType.blackBalloonExplosion);
    onBlackBalloonActivated?.call();
    notifyListeners();
    debugPrint('[GameManager] Black balloon activated');
  }

  /// Activa el efecto del globo reloj (adelanta el tiempo 5s)
  void activateClockBalloon() {
    timerManager.reduceRemainingTime(5.0);
    // Mostrar feedback en UI si es necesario (el Timer widget podría parpadear)
  }

  /// Actualiza el timer del slow motion y el tiempo de juego. Llamar desde game loop.
  void update(double dt) {
    if (slowMotionActive) {
      _slowTimer += dt;
      if (_slowTimer >= _slowDuration) {
        _deactivateSlowMotion();
      }
    }
    
    // Acumular tiempo de juego (solo si está jugando)
    if (_state == GameState.playing && !isFrozen) {
      _playTimeAccumulator += dt;
      if (_playTimeAccumulator >= 5.0) { // Guardar cada 5 segundos para no saturar Hive
        saveManager.addPlayTime(5);
        _playTimeAccumulator -= 5.0;
      }
    }
  }

  /// Vuelve al menú principal
  Future<void> goToMenu() async {
    await audioManager.stopBgm();
    _deactivateSlowMotion();

    // Si el usuario decide volver al menú a mitad de una partida, guardamos su progreso
    if (_state == GameState.paused || _state == GameState.playing) {
      await saveManager.saveGame(
        level: levelManager.currentLevel,
        score: scoreManager.score,
      );
    }

    changeState(GameState.mainMenu);
  }

  /// Vincula la cuenta de Google y sincroniza el progreso fusionando los mayores puntajes
  Future<bool> linkGoogleAccount() async {
    bool success = await cloudSyncManager.linkGoogleAccount();
    if (success) {
      int cloudMaxLevel = (await cloudSyncManager.fetchMaxLevel()) ?? 0;
      int localMaxLevel = saveManager.maxLevelReached;

      final localRecordMap = saveManager.getPersonalRecord();
      final localBestScore = (localRecordMap?['score'] as num?)?.toInt() ?? 0;

      await rankingManager.fetchGlobalRanking();
      final cloudRecordMap = rankingManager.getPersonalRecord();
      final cloudBestScore = rankingManager.getBestScore();

      int finalMaxLevel = math.max(cloudMaxLevel, localMaxLevel);
      int finalBestScore = math.max(cloudBestScore, localBestScore);
      
      Map<String, dynamic>? finalRecordMap;
      if (cloudBestScore > localBestScore && cloudRecordMap != null) {
        finalRecordMap = cloudRecordMap;
      } else {
        finalRecordMap = localRecordMap ?? cloudRecordMap;
      }

      // 1. Sincronizar hacia Local (Si la nube era mayor)
      if (finalMaxLevel > localMaxLevel) {
        await saveManager.saveGame(level: finalMaxLevel, score: 0);
        await saveManager.clearSave(); // Solo queríamos actualizar el maxLevel
      }
      if (finalRecordMap != null && finalBestScore > localBestScore) {
        await saveManager.savePersonalRecord(finalRecordMap);
      }

      // 2. Sincronizar hacia la Nube (Si lo local era mayor)
      if (finalMaxLevel > cloudMaxLevel) {
        await cloudSyncManager.syncMaxLevel(finalMaxLevel);
      }
      if (finalRecordMap != null && finalBestScore > cloudBestScore) {
        final record = ScoreRecord.fromMap(finalRecordMap);
        await rankingManager.addRecord(record);
      }

      notifyListeners();
    }
    return success;
  }

  // -- Privado --

  void _deactivateSlowMotion() {
    if (slowMotionActive) {
      slowMotionActive = false;
      slowMultiplier = 1.0;
      _slowTimer = 0.0;
      eventManager.trigger(GameEventType.slowMotionEnd);
      notifyListeners();
    }
  }

  Future<void> _saveScore() async {
    final record = scoreManager.buildRecord(
      level: levelManager.currentLevel,
    );
    await rankingManager.addRecord(record);
    
    // Guardado local a prueba de balas para el récord personal
    await saveManager.savePersonalRecord(record.toMap());
  }
}
