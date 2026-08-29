// lib/managers/enemy_director.dart
// Director de enemigos: decide QUÉ y CUÁNDO aparece en pantalla

import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/balloon_type.dart';
import '../models/level_config.dart';

/// El EnemyDirector toma decisiones de alto nivel sobre la aparición de entidades.
/// Separa la lógica de "qué spawnear" del "cómo spawnear" (SpawnManager).
/// Trabaja con probabilidades según el nivel y el tiempo transcurrido.
class EnemyDirector {
  final Random _random = Random();

  // Estado interno
  double _timeSinceLastBird = 0.0;
  double _timeSinceLastBlue = 0.0;
  double _timeSinceLastBlack = 0.0;
  double _timeSinceLastClock = 0.0;

  // Intervalos mínimos para especiales (segundos)
  static const double _minBirdInterval = 2.0; // Mucho más frecuente
  static const double _minBlueInterval = 30.0;
  static const double _minBlackInterval = 45.0;
  static const double _minClockInterval = 30.0;

  /// Selecciona un tipo de globo normal según las probabilidades del nivel.
  /// NOTA: Únicamente debe retornar tipos de globos normales (yellow, green, red).
  /// La decisión de spawnear un blindado se maneja en [shouldSpawnArmoredBalloon].
  BalloonType selectBalloonType(LevelConfig config) {
    final weights = config.balloonTypeWeights; // [yellow, green, red]
    final roll = _random.nextDouble();
    if (roll < weights[0]) return BalloonType.yellow;
    if (roll < weights[0] + weights[1]) return BalloonType.green;
    return BalloonType.red;
  }

  /// ¿Debe aparecer un ave en este ciclo?
  bool shouldSpawnBird(LevelConfig config) {
    if (_timeSinceLastBird < _minBirdInterval) return false;
    final roll = _random.nextDouble();
    if (roll < config.birdProbability) {
      _timeSinceLastBird = 0.0;
      return true;
    }
    return false;
  }

  /// ¿Debe aparecer el globo azul especial? (Desbloqueo: Nivel 10)
  bool shouldSpawnBlueBalloon(LevelConfig config, int maxLevelReached) {
    if (maxLevelReached < 10) return false;
    
    if (_timeSinceLastBlue < _minBlueInterval) return false;
    final roll = _random.nextDouble();
    if (roll < config.blueBalloonProbability) {
      _timeSinceLastBlue = 0.0;
      return true;
    }
    return false;
  }

  /// Determina si debe aparecer un globo blindado en el ciclo actual.
  bool shouldSpawnArmoredBalloon(LevelConfig config, int maxLevelReached) {
    if (maxLevelReached < 20) return false;
    
    //Evalúa la probabilidad configurada para globos blindados
    final roll = _random.nextDouble();
    if (roll < config.armoredBalloonProbability) {
      return true;
    }
    return false;
  }

  /// ¿Debe aparecer el globo negro especial? (Desbloqueo: Nivel 30)
  bool shouldSpawnBlackBalloon(LevelConfig config, int maxLevelReached) {
    if (maxLevelReached < 30) return false;
    
    if (_timeSinceLastBlack < _minBlackInterval) return false;
    final roll = _random.nextDouble();
    if (roll < config.blackBalloonProbability) {
      _timeSinceLastBlack = 0.0;
      return true;
    }
    return false;
  }

  /// ¿Debe aparecer el globo reloj especial? (Desbloqueo: Nivel 40)
  bool shouldSpawnClockBalloon(LevelConfig config, int maxLevelReached) {
    if (maxLevelReached < 40) return false;
    
    if (_timeSinceLastClock < _minClockInterval) return false;
    final roll = _random.nextDouble();
    if (roll < config.clockBalloonProbability) {
      _timeSinceLastClock = 0.0;
      return true;
    }
    return false;
  }

  /// Calcula el intervalo hasta el próximo spawn de globo (con variación)
  double nextSpawnDelay(LevelConfig config) {
    final base = config.spawnInterval;
    final variation = (_random.nextDouble() - 0.5) * 0.3 * base;
    return (base + variation).clamp(0.3, 3.0);
  }

  /// Actualiza los contadores internos de tiempo.
  /// Llamar desde el game loop (update(dt))
  void update(double dt) {
    _timeSinceLastBird += dt;
    _timeSinceLastBlue += dt;
    _timeSinceLastBlack += dt;
    _timeSinceLastClock += dt;
  }

  /// Resetea contadores al iniciar nuevo nivel
  void reset() {
    _timeSinceLastBird = 0.0;
    _timeSinceLastBlue = _minBlueInterval / 2; // no aparece inmediatamente
    _timeSinceLastBlack = _minBlackInterval / 2;
    _timeSinceLastClock = _minClockInterval / 2;
    debugPrint('[EnemyDirector] Reset');
  }
}