// lib/managers/score_manager.dart
// GestiA3n de puntuaciA3n, combos y estadA-sticas de la partida

import 'package:flutter/firestore/cloud_firestore.dart';
import '../utils/constants.dart';
import '../models/score_record.dart';
import '../managers/level_manager.dart';

/// Gestiona la puntuaciA3n en tiempo real, el sistema de combos
/// y las estadA-sticas de precisiA3n de la partida actual.
class ScoreManager extends ChangeNotifier {
  int _score = 0;
  int _combo = 0;
  int _maxCombo = 0;
  int _balloonsDestroyed = 0;
  int _totalTaps = 0;        // taps sobre cualquier cosa
  int _successfulTaps = 0;   // taps que acertaron un globo
  int _levelStartScore = 0;  // puntuaciA3n al inicio del nivel actual
  final LevelManager _levelManager = LevelManager();

  ScoreManager() {
    _levelManager.addListener(_onLevelChanged);
  }

  void _onLevelChanged() {
    notifyListeners();
  }

  int get score => _score;
  int get combo => _combo;
  int get maxCombo => _maxCombo;
  int get balloonsDestroyed => _balloonsDestroyed;

  /// Multiplicador de nivel: cada 10 niveles a partir del 20
  /// Niveles 1-19: x1, 20-29: x2, 30-39: x3, etc.
  int get levelMultiplier {
    if (_levelManager.currentLevel < 20) return 1;
    return (_levelManager.currentLevel ~/ 10); // dividida entera: 80 ? 8, 50 ? 5, etc.
  }

  /// Multiplicador de combo segA?n el nA?mero de impactos consecutivos
  double get comboMultiplier {
    if (_combo >= GameConstants.comboThreshold3) return 3.0;
    if (_combo >= GameConstants.comboThreshold2) return 2.0;
    if (_combo >= GameConstants.comboThreshold1) return 1.5;
    return 1.0;
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

    final levelMult = _levelManager.levelMultiplier;
    final multiplier = isBlackBalloon ? 1.0 : comboMultiplier * levelMult;
    final earned = (basePoints * multiplier).round();
    _score += earned;
    notifyListeners();
  }

  /// Suma puntos de mA?ltiples globos (globo negro)
  void addBulkPoints(int totalPoints, int count) {
    _score += totalPoints;
    _balloonsDestroyed += count;
    notifyListeners();
  }

  /// Registra un tap fallido (no golpeA3 nada)
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

  /// Construye un ScoreRecord con las estadA-sticas actuales de la partida
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