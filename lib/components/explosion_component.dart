// lib/components/explosion_component.dart
// Efecto de explosión de partículas al reventar un globo

import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../models/balloon_type.dart';
import '../utils/constants.dart';

/// Partícula individual de la explosión
class _Particle {
  Vector2 position;
  Vector2 velocity;
  double life;
  double maxLife;
  Color color;
  double size;
  double rotation;
  double rotationSpeed;

  _Particle({
    required this.position,
    required this.velocity,
    required this.life,
    required this.maxLife,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
  });

  bool get isDead => life <= 0;
  double get progress => (life / maxLife).clamp(0.0, 1.0);
}

/// Componente de explosión con partículas al reventar un globo.
/// Soporta Object Pooling: usar configure() para reutilizar.
class ExplosionComponent extends PositionComponent {
  final List<_Particle> _particles = [];
  bool _active = false;
  BalloonType _type = BalloonType.yellow;
  dynamic _pool;
  bool _finished = false;

  final Random _random = Random();

  ExplosionComponent() {
    anchor = Anchor.center;
  }

  /// Configura la explosión antes de añadirla al juego
  void configure({
    required Vector2 position,
    required BalloonType type,
    dynamic pool,
  }) {
    this.position = position;
    _type = type;
    _pool = pool;
    _active = true;
    _finished = false;
    _particles.clear();
    _spawnParticles();
  }

  void _spawnParticles() {
    final count = 18 + _random.nextInt(12); // 18–30 partículas
    final baseColor = _type.particleColor;
    final brightColor = _type.glowColor;

    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * pi + _random.nextDouble() * 0.5;
      final speed = 60.0 + _random.nextDouble() * 180.0;
      final life = 0.4 + _random.nextDouble() * 0.5;

      // Alternar entre color base y color brillante
      final color = _random.nextBool() ? baseColor : brightColor;

      _particles.add(_Particle(
        position: Vector2.zero(),
        velocity: Vector2(cos(angle) * speed, sin(angle) * speed),
        life: life,
        maxLife: life,
        color: color,
        size: 4.0 + _random.nextDouble() * 8.0,
        rotation: _random.nextDouble() * 2 * pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 10,
      ));
    }

    // Para globo negro: partículas extra más grandes
    if (_type == BalloonType.black) {
      for (int i = 0; i < 20; i++) {
        final angle = _random.nextDouble() * 2 * pi;
        final speed = 100.0 + _random.nextDouble() * 250.0;
        final life = 0.5 + _random.nextDouble() * 0.6;
        final colors = [
          const Color(0xFF9B59B6),
          const Color(0xFFE74C3C),
          const Color(0xFFF39C12),
          const Color(0xFF3498DB),
        ];

        _particles.add(_Particle(
          position: Vector2.zero(),
          velocity: Vector2(cos(angle) * speed, sin(angle) * speed),
          life: life,
          maxLife: life,
          color: colors[_random.nextInt(colors.length)],
          size: 6.0 + _random.nextDouble() * 12.0,
          rotation: _random.nextDouble() * 2 * pi,
          rotationSpeed: (_random.nextDouble() - 0.5) * 15,
        ));
      }
    }
  }

  @override
  void update(double dt) {
    if (!_active) return;

    bool anyAlive = false;
    for (final p in _particles) {
      if (p.isDead) continue;
      anyAlive = true;

      p.position += p.velocity * dt;
      p.velocity *= (1.0 - dt * 3.0); // Fricción
      p.velocity.y += 200 * dt; // Gravedad leve
      p.life -= dt;
      p.rotation += p.rotationSpeed * dt;
    }

    if (!anyAlive && !_finished) {
      _finished = true;
      _active = false;
      if (_pool != null) {
        _pool.release(this);
      } else {
        removeFromParent();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_active) return;

    for (final p in _particles) {
      if (p.isDead) continue;

      final alpha = (p.progress * p.progress).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = p.color.withOpacity(alpha)
        ..maskFilter = p.size > 8
            ? const MaskFilter.blur(BlurStyle.normal, 3)
            : null;

      canvas.save();
      canvas.translate(p.position.x, p.position.y);
      canvas.rotate(p.rotation);

      // Formas alternadas: círculos y cuadrados pequeños
      if (p.size > 8) {
        canvas.drawCircle(Offset.zero, p.size * p.progress, paint);
      } else {
        final half = p.size * p.progress * 0.5;
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: half * 2, height: half * 2), paint);
      }

      canvas.restore();
    }
  }
}
