// lib/models/level_config.dart
// Configuración calculada para cada nivel del juego

import '../utils/constants.dart';

/// Configuración de un nivel específico, calculada a partir del número de nivel.
/// Centraliza toda la lógica de progresión de dificultad.
class LevelConfig {
  final int level;

  const LevelConfig(this.level);

  /// Multiplicador de velocidad global según el grupo de niveles.
  /// Aumenta un 20% cada 5 niveles.
  double get speedMultiplier {
    final groupIndex = (level - 1) ~/ GameConstants.speedLevelGroupSize;
    return 1.0 + groupIndex * GameConstants.speedLevelIncrement;
  }

  /// Intervalo entre spawns en segundos (decrece con el nivel).
  double get spawnInterval {
    final calculated = GameConstants.spawnIntervalBase -
        (level * GameConstants.spawnIntervalDecrement);
    return calculated.clamp(
      GameConstants.spawnIntervalMin,
      GameConstants.spawnIntervalBase,
    );
  }

  /// Probabilidad base de que aparezca un ave en cada ciclo de spawn.
  double get birdProbability {
    return (0.15 + level * 0.015).clamp(0.15, 0.40);
  }

  /// Probabilidad de que aparezca el globo azul especial.
  double get blueBalloonProbability {
    return 0.012; // ~1.2% por ciclo → aprox 1 cada 45-60s
  }

  /// Probabilidad de que aparezca el globo negro especial.
  double get blackBalloonProbability {
    return 0.006; // ~0.6% por ciclo → aprox 1 cada 90-120s
  }

  /// Probabilidad de que aparezca el globo reloj especial.
  double get clockBalloonProbability {
    return 0.020; // ~2.0% por ciclo
  }

  /// Probabilidad de que aparezca un globo blindado.
  double get armoredBalloonProbability {
    if (level < 60) return 0.0;
    // Inicia en 3% y sube gradualmente
    return (0.03 + (level - 60) * 0.002).clamp(0.0, 0.10);
  }

  /// Distribución de probabilidades para globos normales [yellow, green, red].
  List<double> get balloonTypeWeights {
    if (level <= 5) {
      return [0.60, 0.30, 0.10];
    } else if (level <= 10) {
      return [0.50, 0.35, 0.15];
    } else if (level <= 15) {
      return [0.45, 0.35, 0.20];
    } else {
      return [0.40, 0.35, 0.25];
    }
  }

  /// Duración del nivel en segundos (siempre 60s)
  double get levelDuration => GameConstants.levelDuration;

  /// Retorna la característica desbloqueada según la progresión cada 10 niveles.
  /// Orden: 1-10: Azul, 11-20: Blindado, 21-30: Naturaleza, 31-40: Bomba,
  /// 41-50: Desierto, 51-60: Reloj, 61-70: Colinas, 71-80: Sin especificar
  String get unlockedFeature {
    if (level >= 1 && level <= 10) return 'Globo azul (hielo)';
    if (level >= 11 && level <= 20) return 'Globo blindado';
    if (level >= 21 && level <= 30) return 'Tema naturaleza';
    if (level >= 31 && level <= 40) return 'Globo bomba';
    if (level >= 41 && level <= 50) return 'Tema desierto';
    if (level >= 51 && level <= 60) return 'Globo reloj';
    if (level >= 61 && level <= 70) return 'Tema colinas';
    if (level >= 71 && level <= 80) return 'Por especificar';
    return 'Sin novedades';
  }

  @override
  String toString() =>
      'LevelConfig(level: $level, speedMult: ${speedMultiplier.toStringAsFixed(2)}, spawnInterval: ${spawnInterval.toStringAsFixed(2)}s, feature: $unlockedFeature)';
}
