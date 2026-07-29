// lib/components/ice_effect_component.dart
// Efecto visual de pantalla congelada al activar el globo azul

import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Componente de efecto visual que simula congelación de pantalla.
/// Se muestra durante los 5 segundos del slow motion del globo azul.
/// Aparece con un borde de hielo y partículas de cristal.
class IceEffectComponent extends PositionComponent with HasGameReference {
  double _timer = 0.0;
  bool _active = false;
  final List<_IceCrystal> _crystals = [];
  final Random _random = Random();
  double _borderOpacity = 0.0;

  IceEffectComponent() {
    priority = 10; // Sobre los globos pero bajo el HUD
  }

  @override
  void onMount() {
    super.onMount();
    size = game.size;
    _activate();
  }

  void _activate() {
    _active = true;
    _timer = 0.0;
    _borderOpacity = 0.0;
    _crystals.clear();

    // Generar cristales de hielo en los bordes de la pantalla
    for (int i = 0; i < 40; i++) {
      final edge = _random.nextInt(4);
      double x, y;
      switch (edge) {
        case 0: // top
          x = _random.nextDouble() * game.size.x;
          y = _random.nextDouble() * 60;
          break;
        case 1: // bottom
          x = _random.nextDouble() * game.size.x;
          y = game.size.y - _random.nextDouble() * 60;
          break;
        case 2: // left
          x = _random.nextDouble() * 60;
          y = _random.nextDouble() * game.size.y;
          break;
        default: // right
          x = game.size.x - _random.nextDouble() * 60;
          y = _random.nextDouble() * game.size.y;
          break;
      }
      _crystals.add(_IceCrystal(
        x: x,
        y: y,
        size: 8 + _random.nextDouble() * 20,
        angle: _random.nextDouble() * 2 * pi,
        opacity: 0.3 + _random.nextDouble() * 0.5,
      ));
    }
  }

  @override
  void update(double dt) {
    if (!_active) return;
    _timer += dt;

    // Fade in rápido
    if (_timer < 0.3) {
      _borderOpacity = _timer / 0.3;
    }
    // Fade out en los últimos 1.5 segundos
    else if (_timer > GameConstants.slowMotionDuration - 1.5) {
      _borderOpacity = ((GameConstants.slowMotionDuration - _timer) / 1.5).clamp(0.0, 1.0);
    } else {
      _borderOpacity = 1.0;
    }

    if (_timer >= GameConstants.slowMotionDuration) {
      _active = false;
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_active || _borderOpacity <= 0) return;

    // Overlay de tono azul muy sutil
    canvas.drawRect(
      Rect.fromLTWH(0, 0, game.size.x, game.size.y),
      Paint()..color = const Color(0x0800B4D8).withOpacity(0.04 * _borderOpacity),
    );

    // Borde de hielo
    final borderPaint = Paint()
      ..color = const Color(0xFF00B4D8).withOpacity(0.5 * _borderOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawRect(
      Rect.fromLTWH(4, 4, game.size.x - 8, game.size.y - 8),
      borderPaint,
    );

    // Cristales de hielo en los bordes
    for (final crystal in _crystals) {
      _drawCrystal(canvas, crystal, _borderOpacity);
    }
  }

  void _drawCrystal(Canvas canvas, _IceCrystal crystal, double opacity) {
    canvas.save();
    canvas.translate(crystal.x, crystal.y);
    canvas.rotate(crystal.angle);

    final paint = Paint()
      ..color = const Color(0xFF90E0EF).withOpacity(crystal.opacity * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Dibuja un cristal hexagonal simplificado
    for (int i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(-crystal.size, 0),
        Offset(crystal.size, 0),
        paint,
      );
      canvas.rotate(pi / 3);
    }

    // Pequeño punto central
    canvas.drawCircle(
      Offset.zero,
      3,
      Paint()..color = Colors.white.withOpacity(opacity * 0.7),
    );

    canvas.restore();
  }
}

class _IceCrystal {
  final double x;
  final double y;
  final double size;
  final double angle;
  final double opacity;

  const _IceCrystal({
    required this.x,
    required this.y,
    required this.size,
    required this.angle,
    required this.opacity,
  });
}
