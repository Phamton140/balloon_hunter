// lib/components/bird_component.dart
// Componente de ave rediseñado como ave de origami premium
// Sube verticalmente para confundir con globos.

import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Componente de ave que sube verticalmente. Al ser tocada → GAME OVER.
class BirdComponent extends PositionComponent with TapCallbacks, HasGameReference {
  double _baseSpeed = 0.0;
  double _speedMultiplier = 1.0;
  double _time = 0.0;
  double _startX = 0.0;
  bool _active = false;
  bool _tapped = false;
  
  // Parámetros de movimiento errático
  double _zigZagFreq = 2.5;
  double _zigZagAmp = 35.0;
  double _dashTimer = 0.0;

  // Alas animadas
  double _wingTime = 0.0;
  double _wingAngle = 0.0;

  // Pool
  dynamic _pool;

  // Callbacks
  void Function(BirdComponent)? onTapped;
  final Random _random = Random();

  BirdComponent() {
    width = GameConstants.birdWidth;
    height = GameConstants.birdHeight;
    anchor = Anchor.center;
  }

  /// Configura el ave antes de añadirla al juego
  void configure({
    required double x,
    required double y,
    required bool fromLeft, // ignorado visualmente, pero se recibe
    dynamic pool,
  }) {
    _pool = pool;
    _tapped = false;
    _active = true;
    _time = 0.0;
    _wingTime = 0.0;
    _startX = x;

    position.x = x;
    position.y = y;

    // Velocidad similar a los globos rápidos
    _baseSpeed = 150.0 + _random.nextDouble() * 100.0;
    _speedMultiplier = 1.0;
    
    // Movimiento errático base
    _zigZagFreq = 1.5 + _random.nextDouble() * 2.0;
    _zigZagAmp = 30.0 + _random.nextDouble() * 40.0;
    _dashTimer = _random.nextDouble() * 2.0;
  }

  void applySlowMultiplier(double multiplier) {
    _speedMultiplier = multiplier;
  }

  @override
  void update(double dt) {
    if (!_active) return;
    super.update(dt);

    _time += dt;
    _wingTime += dt * 15.0; // Aleteo rápido
    _wingAngle = sin(_wingTime) * 0.5;

    _dashTimer -= dt;
    if (_dashTimer <= 0) {
      // Cambio de comportamiento errático
      _dashTimer = 1.0 + _random.nextDouble() * 2.0;
      _zigZagFreq = 1.0 + _random.nextDouble() * 4.0;
      _zigZagAmp = 20.0 + _random.nextDouble() * 60.0;
      _baseSpeed = 100.0 + _random.nextDouble() * 200.0;
    }

    // Ascenso vertical como globo
    position.y -= (_baseSpeed * _speedMultiplier) * dt;
    
    // Zig-zag horizontal
    position.x = _startX + sin(_time * _zigZagFreq) * _zigZagAmp;

    // Verificar si escapó por arriba
    if (position.y < -GameConstants.birdHeight) {
      _deactivate();
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_active) return;

    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);

    // Diseño premium de origami ave
    _renderFallbackBird(canvas);

    canvas.restore();
  }

  void _renderFallbackBird(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFFFF3366); // Rosa neón
    final darkPaint = Paint()..color = const Color(0xFFD81B60); // Más oscuro
    final highlightPaint = Paint()..color = const Color(0xFFFF80AB); // Brillo
    final glowPaint = Paint()
      ..color = const Color(0xFFFF3366).withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    // Aura
    canvas.drawCircle(Offset.zero, 25, glowPaint);

    // Movimiento del ala 3D
    final wingOffsetY = sin(_wingAngle) * 18;

    // Ala Izquierda
    final pathLeft = Path()
      ..moveTo(0, -10)
      ..lineTo(-25, wingOffsetY)
      ..lineTo(-5, 15)
      ..close();
    canvas.drawPath(pathLeft, paint);

    // Ala Derecha
    final pathRight = Path()
      ..moveTo(0, -10)
      ..lineTo(25, wingOffsetY)
      ..lineTo(5, 15)
      ..close();
    canvas.drawPath(pathRight, darkPaint);

    // Cuerpo / Cabeza
    final body = Path()
      ..moveTo(0, -28) // Pico
      ..lineTo(8, -8)
      ..lineTo(0, 22) // Cola
      ..lineTo(-8, -8)
      ..close();
    canvas.drawPath(body, highlightPaint);

    // Ojos (destellos)
    canvas.drawCircle(const Offset(-3, -12), 2, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(3, -12), 2, Paint()..color = Colors.white);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (!_active || _tapped) return;
    _tapped = true;
    _active = false;
    onTapped?.call(this);
    if (_pool != null) {
      _pool.release(this);
    } else {
      removeFromParent();
    }
  }

  void _deactivate() {
    _active = false;
    if (_pool != null) {
      _pool.release(this);
    } else {
      removeFromParent();
    }
  }
}
