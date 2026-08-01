// lib/components/bird_component.dart
// Componente de ave rediseñado como ave de origami premium
// Sube verticalmente para confundir con globos.

import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import '../models/level_config.dart';
import '../models/game_state.dart';
import '../utils/constants.dart';
import '../balloon_hunter_game.dart';

/// Representa un ave (obstáculo).
/// Si el jugador la toca, es Game Over.
class BirdComponent extends PositionComponent
    with TapCallbacks, HasGameReference<BalloonHunterGame> {
  double _baseSpeed = 0.0;
  double _speedMultiplier = 1.0;
  double _time = 0.0;
  double _startX = 0.0;
  bool _active = false;
  bool get isActive => _active;
  bool _tapped = false;
  
  // Parámetros de movimiento errático
  double _targetX = 0.0;
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
    priority = 10; // Siempre frente a los globos (z-index mayor)
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
    _targetX = x;

    position.x = x;
    position.y = y;

    // Velocidad similar a los globos rápidos
    _baseSpeed = 150.0 + _random.nextDouble() * 100.0;
    _speedMultiplier = 1.0;
    
    // Movimiento errático base
    _targetX = _startX;
    _dashTimer = _random.nextDouble() * 2.0;
  }

  void applySlowMultiplier(double multiplier) {
    _speedMultiplier = multiplier;
  }

  @override
  void update(double dt) {
    if (!_active) return;
    if (game.gameManager.state != GameState.playing || game.gameManager.isFrozen) return;
    
    super.update(dt);

    _time += dt;
    _wingTime += dt * 15.0; // Aleteo rápido
    _wingAngle = sin(_wingTime) * 0.5;

    _dashTimer -= dt;
    if (_dashTimer <= 0) {
      // Cambio de comportamiento errático suave
      _dashTimer = 1.0 + _random.nextDouble() * 2.0;
      
      // Elige un nuevo objetivo X dentro de un rango de su posición inicial
      double offset = (_random.nextDouble() * 2 - 1) * 80.0; // +/- 80px
      _targetX = _startX + offset;
      
      _baseSpeed = 100.0 + _random.nextDouble() * 150.0;
    }

    // Ascenso vertical como globo
    position.y -= (_baseSpeed * _speedMultiplier) * dt;
    
    // Movimiento suave hacia el objetivo X
    double diffX = _targetX - position.x;
    position.x += diffX * 2.0 * dt; // El factor 2.0 controla qué tan rápido se acerca al objetivo

    // Verificar si escapó por arriba (al entrar al menú superior)
    if (position.y + (GameConstants.birdHeight / 2) < GameConstants.hudHeight) {
      disappear();
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_active) return;

    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);

    // Diseño realista caricaturizado
    _renderRealisticBird(canvas);

    canvas.restore();
  }

  void _renderRealisticBird(Canvas canvas) {
    // Definimos colores para un ave rosada (para contrastar con el cielo azul)
    final bodyColor = const Color(0xFFFF4081); // Rosa brillante
    final bellyColor = const Color(0xFFF8BBD0); // Rosa claro para la barriga
    final wingColor = const Color(0xFFE91E63); // Rosa más oscuro para las alas
    final beakColor = const Color(0xFFFFCA28); // Amarillo (se mantiene igual)
    final tailColor = const Color(0xFFD81B60); // Rosa intenso para la cola

    final paintBody = Paint()..color = bodyColor;
    final paintBelly = Paint()..color = bellyColor;
    final paintWing = Paint()..color = wingColor;
    final paintBeak = Paint()..color = beakColor;
    final paintTail = Paint()..color = tailColor;

    // Movimiento del ala (simulando 3D con escalado)
    final flapValue = sin(_wingTime); 
    final wingScaleY = flapValue.abs() * 0.8 + 0.2; // Escala Y entre 0.2 y 1.0
    final wingOffsetY = flapValue * 4;

    // Sombra para profundidad
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, 4), width: 32, height: 44), shadowPaint);

    // 1. Cola
    final tailPath = Path()
      ..moveTo(0, 10)
      ..lineTo(-8, 24)
      ..lineTo(0, 28)
      ..lineTo(8, 24)
      ..close();
    canvas.drawPath(tailPath, paintTail);

    // 2. Alas (dibujadas debajo del cuerpo)
    // Ala Izquierda
    canvas.save();
    canvas.translate(-9, 2 + wingOffsetY);
    canvas.scale(1.0, wingScaleY);
    final leftWing = Path()
      ..moveTo(0, -6)
      ..quadraticBezierTo(-22, -15, -25, 5)
      ..quadraticBezierTo(-15, 12, 0, 8)
      ..close();
    canvas.drawPath(leftWing, paintWing);
    canvas.restore();

    // Ala Derecha
    canvas.save();
    canvas.translate(9, 2 + wingOffsetY);
    canvas.scale(1.0, wingScaleY);
    final rightWing = Path()
      ..moveTo(0, -6)
      ..quadraticBezierTo(22, -15, 25, 5)
      ..quadraticBezierTo(15, 12, 0, 8)
      ..close();
    canvas.drawPath(rightWing, paintWing);
    canvas.restore();

    // 3. Cuerpo
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, 6), width: 22, height: 28), paintBody);
    
    // Barriga
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, 8), width: 14, height: 20), paintBelly);

    // 4. Cabeza
    canvas.drawCircle(const Offset(0, -10), 12, paintBody);

    // 5. Pico
    final beak = Path()
      ..moveTo(-5, -14)
      ..lineTo(5, -14)
      ..lineTo(0, -24)
      ..close();
    canvas.drawPath(beak, paintBeak);
    // Linea central del pico
    canvas.drawLine(const Offset(0, -14), const Offset(0, -23), Paint()..color = Colors.orange..strokeWidth = 1);

    // 6. Ojos
    final eyePaint = Paint()..color = Colors.white;
    final pupilPaint = Paint()..color = Colors.black;
    // Ojo Izquierdo
    canvas.drawCircle(const Offset(-5, -11), 3.5, eyePaint);
    canvas.drawCircle(const Offset(-5, -12), 1.5, pupilPaint); // Mira hacia arriba
    // Ojo Derecho
    canvas.drawCircle(const Offset(5, -11), 3.5, eyePaint);
    canvas.drawCircle(const Offset(5, -12), 1.5, pupilPaint);
    
    // 7. Cejas enojadas (para darle personalidad de enemigo)
    final browPaint = Paint()
      ..color = const Color(0xFF880E4F) // Rosa súper oscuro casi vino
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(-8, -15), const Offset(-2, -13), browPaint);
    canvas.drawLine(const Offset(8, -15), const Offset(2, -13), browPaint);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (!_active || game.gameManager.isFrozen) return;
    _active = false;
    
    // Reproducir sonido de Game Over
    game.gameManager.audioManager.playBirdHit();
    
    // Congelar el juego para la animación
    game.gameManager.freezeForGameOver();
    
    // Reproducir explosión visual
    final explosion = ParticleSystemComponent(
      position: position,
      particle: Particle.generate(
        count: 40,
        lifespan: 1.5,
        generator: (i) {
          final random = Random();
          final speed = random.nextDouble() * 200 + 50;
          final angle = random.nextDouble() * 2 * pi;
          final vx = cos(angle) * speed;
          final vy = sin(angle) * speed;
          
          return AcceleratedParticle(
            acceleration: Vector2(0, 300), // Gravedad
            speed: Vector2(vx, vy),
            position: Vector2.zero(),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final paint = Paint()
                  ..color = const Color(0xFFFF3366).withOpacity(1 - particle.progress);
                canvas.drawCircle(Offset.zero, 3 + random.nextDouble() * 4, paint);
              },
            ),
          );
        },
      ),
    );
    game.add(explosion);

    // Esperar 2 segundos y disparar Game Over
    Future.delayed(const Duration(seconds: 2), () {
      if (game.gameManager.isFrozen) {
        game.gameManager.triggerGameOver();
      }
    });
  }

  void disappear() {
    _active = false;
    if (_pool != null) {
      _pool.release(this);
    } else {
      removeFromParent();
    }
  }
  @override
  bool containsLocalPoint(Vector2 point) {
    if (!_active) return false;
    // Reducido a 5.0 para que sea más difícil darle por accidente al ave
    final margin = 5.0;
    return point.x >= -margin &&
           point.y >= -margin &&
           point.x <= size.x + margin &&
           point.y <= size.y + margin;
  }
}
