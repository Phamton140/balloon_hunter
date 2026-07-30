// lib/managers/level_manager.dart
// Gestión de niveles y progresión

import 'package:flutter/foundation.dart';
import '../models/level_config.dart';

/// Gestiona el nivel actual y la progresión del juego.
class LevelManager extends ChangeNotifier {
  int _currentLevel = 1;
  int _escapedBalloons = 0;

  int get currentLevel => _currentLevel;
  int get escapedBalloons => _escapedBalloons;

  /// Configuración calculada para el nivel actual
  LevelConfig get config => LevelConfig(_currentLevel);

  /// Número de estrellas obtenidas según los globos escapados
  int get stars {
    if (_escapedBalloons == 0) return 3;
    if (_escapedBalloons == 1) return 2;
    if (_escapedBalloons == 2) return 1;
    return 0;
  }

  /// Si la partida está perdida (3 globos escapados)
  bool get isGameOver => _escapedBalloons >= 3;

  /// Registra que un globo escapó por la parte superior
  void onBalloonEscaped() {
    _escapedBalloons++;
    notifyListeners();
  }

  /// Avanza al siguiente nivel
  void advanceLevel() {
    _currentLevel++;
    _escapedBalloons = 0;
    notifyListeners();
  }

  /// Resetea al nivel 1 (nueva partida)
  void reset() {
    _currentLevel = 1;
    _escapedBalloons = 0;
    notifyListeners();
  }

  /// Resetea solo los globos escapados (para revivir)
  void resetEscapes() {
    _escapedBalloons = 0;
    notifyListeners();
  }

  /// Carga desde un guardado
  void loadFromSave(int level) {
    _currentLevel = level;
    _escapedBalloons = 0;
    notifyListeners();
  }
}
