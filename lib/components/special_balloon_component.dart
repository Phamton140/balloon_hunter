// lib/components/special_balloon_component.dart
// Globos especiales: Azul (slow motion) y Negro (destroy all)

import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../models/balloon_type.dart';
import '../models/game_state.dart';
import '../utils/constants.dart';
import '../balloon_hunter_game.dart';

/// Componente de globo especial. Aparece brevemente (2-3s) y desaparece solo.
/// Azul: activa slow motion. Negro: destruye todos los globos normales.
/// No usa Object Pool (son muy poco frecuentes).
class SpecialBalloonComponent extends PositionComponent with TapCallbacks, HasGameReference<BalloonHunterGame> {
  BalloonType _type = BalloonType.blue;
  BalloonType get specialType => _type;

  double _lifeTimer = 0.0;
  double _speed = 300.0;
  bool _active = false;
  bool _tapped = false;

  // Animación de pulso
  double _pulseTime = 0.0;
  double _scaleAnim = 1.0;

  // Callbacks
  void Function(SpecialBalloonComponent)? onTapped;

  final Random _random = Random();

  SpecialBalloonComponent() {
    width = GameConstants.balloonWidth * 1.3; // ligeramente más grande
    height = GameConstants.balloonHeight * 1.3;
    anchor = Anchor.center;
  }

  /// Configura el globo especial antes de añadirlo
  void configure({
    required BalloonType type,
    required double x,
    required double y,
  }) {
    assert(type.isSpecial, 'SpecialBalloonComponent solo acepta tipos especiales');
    _type = type;
    _tapped = false;
    _active = true;
    _lifeTimer = 0.0;
    _pulseTime = 0.0;
    _scaleAnim = 1.0;
    
    // Alta velocidad para globos especiales
    _speed = 300.0 + _random.nextDouble() * 100.0;
    position.x = x;
    position.y = y;
  }

  @override
  void update(double dt) {
    if (!_active) return;
    if (game.gameManager.state != GameState.playing || game.gameManager.isFrozen) return;
    super.update(dt);

    _lifeTimer += dt;
    _pulseTime += dt * 3.0;
    _scaleAnim = 1.0 + sin(_pulseTime) * 0.08;

    // Subir a gran velocidad
    position.y -= _speed * dt;
    
    // Ligero balanceo horizontal
    position.x += sin(_pulseTime * 2.0) * 30.0 * dt;

    // Desaparece al salir por arriba
    if (position.y < -GameConstants.balloonHeight) {
      _disappear();
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_active) return;

    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.scale(_scaleAnim);

    final alpha = 1.0;

    if (_type == BalloonType.blue) {
      _renderBlueBalloon(canvas, alpha);
    } else {
      _renderBlackBalloon(canvas, alpha);
    }

    canvas.restore();
  }

  void _renderBlueBalloon(Canvas canvas, double alpha) {
    // Aura de hielo
    final auraPaint = Paint()
      ..color = const Color(0xFF00B4D8).withOpacity(0.3 * alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(Offset.zero, 55, auraPaint);

    // Cuerpo
    final bodyPaint = Paint()
      ..color = const Color(0xFF00B4D8).withOpacity(alpha);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: GameConstants.balloonWidth * 1.3,
        height: GameConstants.balloonHeight * 1.1,
      ),
      bodyPaint,
    );

    // Cristales de hielo
    final crystalPaint = Paint()
      ..color = Colors.white.withOpacity(0.6 * alpha)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 6; i++) {
      final angle = i * pi / 3;
      canvas.drawLine(
        Offset.zero,
        Offset(cos(angle) * 20, sin(angle) * 20),
        crystalPaint,
      );
    }

    // Brillo
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(-10, -14),
        width: 16,
        height: 22,
      ),
      Paint()..color = Colors.white.withOpacity(0.5 * alpha),
    );

    // Label
    _drawLabel(canvas, '❄', alpha);

    // Hilo y nudo
    _drawString(canvas, const Color(0xFF00B4D8).withOpacity(alpha));
  }

  void _renderBlackBalloon(Canvas canvas, double alpha) {
    // Aura púrpura
    final auraPaint = Paint()
      ..color = const Color(0xFF9B59B6).withOpacity(0.5 * alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(Offset.zero, 60, auraPaint);

    // Cuerpo negro
    final bodyPaint = Paint()
      ..color = const Color(0xFF1A0A2E).withOpacity(alpha);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: GameConstants.balloonWidth * 1.3,
        height: GameConstants.balloonHeight * 1.1,
      ),
      bodyPaint,
    );

    // Espiral mágica
    final spiralPaint = Paint()
      ..color = const Color(0xFF9B59B6).withOpacity(0.7 * alpha)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path();
    for (double t = 0; t < 4 * pi; t += 0.1) {
      final r = t * 4;
      final x = cos(t) * r;
      final y = sin(t) * r;
      if (t == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, spiralPaint);

    // Brillo
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(-10, -14),
        width: 14,
        height: 20,
      ),
      Paint()..color = Colors.white.withOpacity(0.3 * alpha),
    );

    // Label
    _drawLabel(canvas, '💥', alpha);

    // Hilo y nudo
    _drawString(canvas, const Color(0xFF1A0A2E).withOpacity(alpha));
  }

  void _drawString(Canvas canvas, Color knotColor) {
    final knotY = GameConstants.balloonHeight * 0.55;
    
    // Nudo
    canvas.drawCircle(Offset(0, knotY), 5, Paint()..color = knotColor);

    // Hilo
    final stringPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final stringPath = Path();
    stringPath.moveTo(0, knotY + 2);
    stringPath.quadraticBezierTo(
      sin(_pulseTime * 2) * 12, knotY + 15,
      -sin(_pulseTime * 2) * 8, knotY + 30
    );
    canvas.drawPath(stringPath, stringPaint);
  }

  void _drawLabel(Canvas canvas, String emoji, double alpha) {
    final tp = TextPainter(
      text: TextSpan(
        text: emoji,
        style: TextStyle(fontSize: 22, color: Colors.white.withOpacity(alpha)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, tp.height * 0.8));
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (!_active || _tapped) return;
    _tapped = true;
    _active = false;
    onTapped?.call(this);
    removeFromParent();
  }

  void _disappear() {
    _active = false;
    removeFromParent();
  }
}
