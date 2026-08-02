// lib/components/background_component.dart
// Fondo animado del juego con cambio dinámico basado en tiempo real

import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

enum TimeOfDayCategory { morning, afternoon, night }

/// Fondo del juego con imagen de cielo que cambia dinámicamente según la hora local.
/// Añade nubes animadas superpuestas para efecto dinámico.
class BackgroundComponent extends PositionComponent with HasGameReference {
  late Sprite _morningSprite;
  late Sprite _afternoonSprite;
  late Sprite _nightSprite;

  final List<_Cloud> _clouds = [];
  final Random _random = Random();
  bool _spritesLoaded = false;

  TimeOfDayCategory _currentCategory = TimeOfDayCategory.morning;
  TimeOfDayCategory? _previousCategory;

  double _fadeTimer = 0.0;
  static const double _fadeDuration = 3.0; // 3 segundos de transición suave
  double _checkTimeTimer = 0.0;

  @override
  Future<void> onLoad() async {
    size = game.size;
    priority = -10; // Siempre al fondo

    try {
      _morningSprite = await Sprite.load('bg_morning.png');
      _afternoonSprite = await Sprite.load('bg_afternoon.png');
      _nightSprite = await Sprite.load('bg_night.png');
      _spritesLoaded = true;

      // Inicializar categoría actual basada en el tiempo real
      _currentCategory = _getTimeOfDayCategory();
    } catch (e) {
      debugPrint('[BackgroundComponent] Error loading backgrounds: $e');
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

  TimeOfDayCategory _getTimeOfDayCategory() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) {
      return TimeOfDayCategory.morning;
    } else if (hour >= 12 && hour < 18) {
      return TimeOfDayCategory.afternoon;
    } else {
      return TimeOfDayCategory.night;
    }
  }

  Sprite _getSpriteForCategory(TimeOfDayCategory category) {
    switch (category) {
      case TimeOfDayCategory.morning:
        return _morningSprite;
      case TimeOfDayCategory.afternoon:
        return _afternoonSprite;
      case TimeOfDayCategory.night:
        return _nightSprite;
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

    if (!_spritesLoaded) return;

    // Actualizar timer de transición
    if (_previousCategory != null) {
      _fadeTimer += dt;
      if (_fadeTimer >= _fadeDuration) {
        _previousCategory = null; // Termina la transición
        _fadeTimer = 0.0;
      }
    }

    // Chequear el reloj real cada 5 segundos para ahorrar CPU
    _checkTimeTimer += dt;
    if (_checkTimeTimer >= 5.0) {
      _checkTimeTimer = 0.0;
      final actualCategory = _getTimeOfDayCategory();
      if (actualCategory != _currentCategory) {
        // Iniciar transición al nuevo fondo
        _previousCategory = _currentCategory;
        _currentCategory = actualCategory;
        _fadeTimer = 0.0;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, game.size.x, game.size.y);

    if (!_spritesLoaded) {
      // Fallback: gradiente de cielo programático mientras cargan las imágenes
      final paint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF87CEEB), Color(0xFFE0F4FF)],
        ).createShader(rect);
      canvas.drawRect(rect, paint);
    } else {
      // Si estamos en transición, dibujamos el viejo fondo primero
      if (_previousCategory != null) {
        final oldSprite = _getSpriteForCategory(_previousCategory!);
        oldSprite.render(canvas, size: game.size);

        // Y encima dibujamos el nuevo fondo con opacidad que va subiendo
        final newSprite = _getSpriteForCategory(_currentCategory);
        final progress = (_fadeTimer / _fadeDuration).clamp(0.0, 1.0);
        final paint = Paint()..color = Colors.white.withOpacity(progress);
        newSprite.render(canvas, size: game.size, overridePaint: paint);
      } else {
        // No hay transición, solo dibujamos el fondo actual sólido
        final currentSprite = _getSpriteForCategory(_currentCategory);
        currentSprite.render(canvas, size: game.size);
      }
    }

    // Dibujar nubes decorativas encima de todo
    for (final cloud in _clouds) {
      _drawCloud(canvas, cloud);
    }
  }

  void _drawCloud(Canvas canvas, _Cloud cloud) {
    // Si es de noche, oscurecemos un poco las nubes
    final baseColor = _currentCategory == TimeOfDayCategory.night ? Colors.blueGrey : Colors.white;
    final paint = Paint()
      ..color = baseColor.withOpacity(cloud.opacity);

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
