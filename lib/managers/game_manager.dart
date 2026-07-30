// lib/managers/game_manager.dart
// Estado global y coordinación central del juego

import 'package:flutter/foundation.dart';
import '../models/game_state.dart';
import '../models/game_event.dart';
import 'audio_manager.dart';
import 'score_manager.dart';
import 'level_manager.dart';
import 'timer_manager.dart';
import 'ranking_manager.dart';
import 'event_manager.dart';
import 'save_manager.dart';

/// Gestor central que coordina todos los subsistemas del juego.
/// Mantiene el estado global y la lógica de transición entre pantallas.
class GameManager extends ChangeNotifier {
  GameManager({
    required this.audioManager,
    required this.scoreManager,
    required this.levelManager,
    required this.timerManager,
    required this.rankingManager,
    required this.eventManager,
    required this.saveManager,
  });

  final AudioManager audioManager;
  final ScoreManager scoreManager;
  final LevelManager levelManager;
  final TimerManager timerManager;
  final RankingManager rankingManager;
  final EventManager eventManager;
  final SaveManager saveManager;

  // -- Estado del Juego --
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
  static const double _slowDuration = 5.0;

  // Callbacks hacia el FlameGame
  VoidCallback? onGameOver;
  VoidCallback? onLevelComplete;
  VoidCallback? onBlackBalloonActivated;

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
    _deactivateSlowMotion();
    changeState(GameState.countdown);
    await audioManager.playBgm();
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
    // Guarda el progreso de manera persistente al avanzar
    await saveManager.saveGame(
      level: levelManager.currentLevel, 
      score: scoreManager.score,
    );
    scoreManager.saveLevelStartScore(); // Guarda score inicial para el nuevo nivel
    timerManager.reset();
    timerManager.start();
    _deactivateSlowMotion();
    changeState(GameState.countdown);
  }

  /// Pausa el juego
  Future<void> pauseGame() async {
    if (_state != GameState.playing) return;
    timerManager.pause();
    changeState(GameState.paused);
    await audioManager.pauseBgm();
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
    
    // Guarda el progreso de manera persistente al completar un nivel,
    // preparándolo para el siguiente (currentLevel + 1)
    await saveManager.saveGame(
      level: levelManager.currentLevel + 1,
      score: scoreManager.score,
    );
    
    changeState(GameState.victory);
    await audioManager.playLevelUp();
    onLevelComplete?.call();
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
    await _saveScore(); // Guarda en el ranking Top 3
    await saveManager.clearSave(); // Borra el progreso del nivel actual
    changeState(GameState.gameOver);
    await audioManager.stopBgm();
    onGameOver?.call();
  }

  /// Revive al jugador tras ver un video (reinicia timer y escapes, revierte puntos)
  Future<void> reviveLevel() async {
    // Restaurar puntuación inicial del nivel (pierde lo ganado antes de morir)
    scoreManager.revertToLevelStartScore();
    // Reiniciar globos escapados
    levelManager.resetEscapes();
    // Reiniciar tiempo
    timerManager.reset();
    timerManager.start();
    _deactivateSlowMotion();
    
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

  /// Actualiza el timer del slow motion. Llamar desde game loop.
  void update(double dt) {
    if (slowMotionActive) {
      _slowTimer += dt;
      if (_slowTimer >= _slowDuration) {
        _deactivateSlowMotion();
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
  }
}
