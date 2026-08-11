// lib/managers/timer_manager.dart
// Temporizador del nivel (countdown de 60 segundos)

import 'package:flutter/foundation.dart';
import '../utils/constants.dart';

/// Gestiona el countdown del nivel.
/// Se actualiza mediante el loop de Flame (update(dt)).
class TimerManager extends ChangeNotifier {
  double _elapsed = 0.0;
  bool _running = false;

  /// Tiempo transcurrido en segundos
  double get elapsed => _elapsed;

  /// Tiempo restante en segundos
  double get remaining =>
      (GameConstants.levelDuration - _elapsed).clamp(0.0, GameConstants.levelDuration);

  /// Si el tiempo se ha agotado
  bool get isTimeUp => _elapsed >= GameConstants.levelDuration;

  bool get isRunning => _running;

  /// Inicia o reanuda el temporizador
  void start() {
    _running = true;
  }

  /// Pausa el temporizador
  void pause() {
    _running = false;
  }

  /// Actualiza el temporizador. Llamar desde BalloonHunterGame.update(dt)
  void update(double dt) {
    if (!_running || isTimeUp) return;
    _elapsed += dt;
    notifyListeners();
  }

  /// Resetea para un nuevo nivel
  void reset() {
    _elapsed = 0.0;
    _running = false;
    notifyListeners();
  }

  /// Adelanta el tiempo (reduce el tiempo restante)
  void reduceRemainingTime(double seconds) {
    if (!_running || isTimeUp) return;
    _elapsed += seconds;
    if (_elapsed >= GameConstants.levelDuration) {
      _elapsed = GameConstants.levelDuration; // Esto dejará remaining en 0 y provocará isTimeUp
    }
    notifyListeners();
  }

  /// Tiempo restante formateado como MM:SS
  String get formattedRemaining {
    final secs = remaining.ceil();
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
