// lib/components/background_component.dart
// Fondo animado del juego (cielo con nubes)

import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Fondo del juego con imagen de cielo cargada como sprite.
/// Añade nubes animadas superpuestas para efecto dinámico.
class BackgroundComponent extends PositionComponent with HasGameReference {
  late Sprite _backgroundSprite;
  final List<_Cloud> _clouds = [];
  final Random _random = Random();
  bool _imageLoaded = false;

  @override
  Future<void> onLoad() async {
    size = game.size;
    priority = -10; // Siempre al fondo

    try {
      _backgroundSprite = await Sprite.load('background.png');
      _imageLoaded = true;
    } catch (e) {
      debugPrint('[BackgroundComponent] Error loading background: $e');
    }

    // Generar nubes decorativas animadas
    for (int i = 0; i < 6; i++) {
      _clouds.add(_Cloud(
        x: _random.nextDouble() * game.size.x,
        y: _random.nextDouble() * game.size.y * 0.5,
        scale: 0.5 + _random.nextDouble() * 0.8,
        speed: 15.0 + _random.nextDouble() * 20.0,
        opacity: 0.4 + _random.nextDouble() * 0.5,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Animar nubes de izquierda a derecha
    for (final cloud in _clouds) {
      cloud.x += cloud.speed * dt;
      if (cloud.x > game.size.x + 200) {
        cloud.x = -200;
        cloud.y = _random.nextDouble() * game.size.y * 0.5;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, game.size.x, game.size.y);

    if (_imageLoaded) {
      _backgroundSprite.render(canvas, size: game.size);
    } else {
      // Fallback: gradiente de cielo programático
      final paint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF87CEEB), Color(0xFFE0F4FF)],
        ).createShader(rect);
      canvas.drawRect(rect, paint);
    }

    // Dibujar nubes decorativas
    for (final cloud in _clouds) {
      _drawCloud(canvas, cloud);
    }
  }

  void _drawCloud(Canvas canvas, _Cloud cloud) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(cloud.opacity);

    final cx = cloud.x;
    final cy = cloud.y;
    final s = cloud.scale * 40;

    canvas.drawCircle(Offset(cx, cy), s, paint);
    canvas.drawCircle(Offset(cx + s * 0.8, cy + s * 0.2), s * 0.75, paint);
    canvas.drawCircle(Offset(cx - s * 0.6, cy + s * 0.2), s * 0.6, paint);
    canvas.drawCircle(Offset(cx + s * 0.3, cy - s * 0.4), s * 0.5, paint);
  }
}

class _Cloud {
  double x;
  double y;
  final double scale;
  final double speed;
  final double opacity;

  _Cloud({
    required this.x,
    required this.y,
    required this.scale,
    required this.speed,
    required this.opacity,
  });
}
