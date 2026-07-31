// lib/models/balloon_type.dart
// Definición de todos los tipos de globo con sus propiedades

import 'package:flutter/material.dart';
import '../utils/palette.dart';

/// Todos los tipos de globo en el juego.
/// Los tipos blue y black son especiales: no dan puntos directamente.
enum BalloonType {
  yellow(
    points: 1,
    baseSpeed: 80.0,
    color: Palette.balloonYellow,
    glowColor: Palette.balloonYellowGlow,
    particleColor: Palette.particleYellow,
    isSpecial: false,
  ),
  green(
    points: 2,
    baseSpeed: 130.0,
    color: Palette.balloonGreen,
    glowColor: Palette.balloonGreenGlow,
    particleColor: Palette.particleGreen,
    isSpecial: false,
  ),
  red(
    points: 3,
    baseSpeed: 180.0,
    color: Palette.balloonRed,
    glowColor: Palette.balloonRedGlow,
    particleColor: Palette.particleRed,
    isSpecial: false,
  ),
  blue(
    points: 0,
    baseSpeed: 100.0,
    color: Palette.balloonBlue,
    glowColor: Palette.balloonBlueGlow,
    particleColor: Palette.particleBlue,
    isSpecial: true,
  ),
  black(
    points: 0,
    baseSpeed: 110.0,
    color: Palette.balloonBlack,
    glowColor: Palette.balloonBlackGlow,
    particleColor: Palette.particleBlack,
    isSpecial: true,
  );

  const BalloonType({
    required this.points,
    required this.baseSpeed,
    required this.color,
    required this.glowColor,
    required this.particleColor,
    required this.isSpecial,
  });

  /// Puntos base que otorga al ser explotado (0 para especiales)
  final int points;

  /// Velocidad base en píxeles/segundo
  final double baseSpeed;

  /// Color principal del globo
  final Color color;

  /// Color de brillo/aura
  final Color glowColor;

  /// Color de las partículas de explosión
  final Color particleColor;

  /// Si es un globo con poder especial (azul o negro)
  final bool isSpecial;

  /// Retorna solo los tipos normales (sin especiales)
  static List<BalloonType> get normal =>
      [BalloonType.yellow, BalloonType.green, BalloonType.red];
}
