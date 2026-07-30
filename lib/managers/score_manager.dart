// lib/managers/score_manager.dart
// Gestión de puntuación, combos y estadísticas de la partida

import 'package:flutter/foundation.dart';
import '../utils/constants.dart';
import '../models/score_record.dart';

/// Gestiona la puntuación en tiempo real, el sistema de combos
/// y las estadísticas de precisión de la partida actual.
class ScoreManager extends ChangeNotifier {
  int _score = 0;
  int _combo = 0;
  int _maxCombo = 0;
  int _balloonsDestroyed = 0;
  int _totalTaps = 0;        // taps sobre cualquier cosa
  int _successfulTaps = 0;   // taps que acertaron un globo
  int _levelStartScore = 0;  // puntuación al inicio del nivel actual

  int get score => _score;
  int get combo => _combo;
  int get maxCombo => _maxCombo;
  int get balloonsDestroyed => _balloonsDestroyed;

  /// Multiplicador de combo según el número de impactos consecutivos
  double get comboMultiplier {
    if (_combo >= GameConstants.comboThreshold3) return 3.0;
    if (_combo >= GameConstants.comboThreshold2) return 2.0;
    if (_combo >= GameConstants.comboThreshold1) return 1.5;
    return 1.0;
  }

  /// Precisión en porcentaje (0-100)
  double get accuracy {
    if (_totalTaps == 0) return 100.0;
    return (_successfulTaps / _totalTaps * 100).clamp(0.0, 100.0);
  }

  /// Registra la puntuación actual como el inicio del nivel (para recompensas)
  void saveLevelStartScore() {
    _levelStartScore = _score;
  }

  /// Restaura la puntuación a la que tenía al iniciar el nivel (al revivir)
  void revertToLevelStartScore() {
    _score = _levelStartScore;
    _combo = 0;
    notifyListeners();
  }

  /// Suma puntos al explotar un globo normal.
  /// [basePoints] es el valor base del tipo de globo.
  /// [isBlackBalloon] indica si los puntos vienen del globo negro especial.
  void addPoints(int basePoints, {bool isBlackBalloon = false}) {
    if (!isBlackBalloon) {
      _combo++;
      _successfulTaps++;
      _totalTaps++;
      _balloonsDestroyed++;
    } else {
      // Globo negro: no incrementa combo, suma directamente
      _balloonsDestroyed += basePoints > 0 ? 1 : 0;
    }

    if (_combo > _maxCombo) _maxCombo = _combo;

    final multiplier = isBlackBalloon ? 1.0 : comboMultiplier;
    final earned = (basePoints * multiplier).round();
    _score += earned;
    notifyListeners();
  }

  /// Suma puntos de múltiples globos (globo negro)
  void addBulkPoints(int totalPoints, int count) {
    _score += totalPoints;
    _balloonsDestroyed += count;
    notifyListeners();
  }

  /// Registra un tap fallido (no golpeó nada)
  void registerMiss() {
    _totalTaps++;
    _combo = 0;
    notifyListeners();
  }

  /// Resetea todo para una nueva partida
  void reset() {
    _score = 0;
    _combo = 0;
    _maxCombo = 0;
    _balloonsDestroyed = 0;
    _totalTaps = 0;
    _successfulTaps = 0;
    notifyListeners();
  }

  /// Construye un ScoreRecord con las estadísticas actuales de la partida
  ScoreRecord buildRecord({required int level}) {
    return ScoreRecord(
      score: _score,
      level: level,
      date: DateTime.now(),
      balloonsDestroyed: _balloonsDestroyed,
      accuracy: accuracy,
      maxCombo: _maxCombo,
    );
  }

  /// Carga desde un guardado
  void loadFromSave(int savedScore) {
    _score = savedScore;
    _combo = 0;
    _maxCombo = 0;
    _totalTaps = 0;
    _successfulTaps = 0;
    _balloonsDestroyed = 0;
    notifyListeners();
  }
}
