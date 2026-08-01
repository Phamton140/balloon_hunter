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
  bool get isActive => _active;
  bool _tapped = false;

  // Animación de pulso
  double _pulseTime = 0.0;
  double _scaleAnim = 1.0;

  // Callbacks
  void Function(SpecialBalloonComponent)? onTapped;

  final Random _random = Random();

  SpecialBalloonComponent() {
    width = GameConstants.balloonWidth;
    height = GameConstants.balloonHeight;
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
    
    // Velocidad más amigable para que el usuario pueda identificarlos y tocarlos
    _speed = 180.0 + _random.nextDouble() * 50.0;
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

    // Desaparece al entrar por completo al menú superior
    if (position.y + (GameConstants.balloonHeight / 2) < GameConstants.hudHeight) {
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

  void _renderBaseBalloon(Canvas canvas, Color baseColor, Color glowColor, double alpha) {
    // 1. Aura de brillo idéntica a los globos normales
    final glowPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.4 * alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: GameConstants.balloonWidth * 1.2,
        height: GameConstants.balloonHeight * 1.1,
      ),
      glowPaint,
    );

    // 2. Cuerpo del globo idéntico a los normales
    final paint = Paint()..color = baseColor.withValues(alpha: alpha);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: GameConstants.balloonWidth,
        height: GameConstants.balloonHeight * 0.85,
      ),
      paint,
    );

    // 3. Brillo especular idéntico
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5 * alpha);
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(-8, -12),
        width: 18,
        height: 24,
      ),
      highlightPaint,
    );

    // 4. Nudo del globo idéntico
    final knotPaint = Paint()..color = baseColor.withValues(alpha: 0.8 * alpha);
    final knotY = GameConstants.balloonHeight * 0.42;
    canvas.drawCircle(
      Offset(0, knotY),
      5,
      knotPaint,
    );

    // 5. Hilo ondulante idéntico
    final stringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4 * alpha)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final stringPath = Path();
    stringPath.moveTo(0, knotY + 2);
    stringPath.quadraticBezierTo(
      sin(_pulseTime * 3) * 12, knotY + 15,
      -sin(_pulseTime * 3) * 8, knotY + 30
    );
    canvas.drawPath(stringPath, stringPaint);
  }

  void _renderBlueBalloon(Canvas canvas, double alpha) {
    // Dibujar la base idéntica a los globos normales, pero azul hielo
    _renderBaseBalloon(canvas, const Color(0xFF29B6F6), const Color(0xFF00B4D8), alpha);

    // Dibujar SOLO el ícono interno de Hielo (Copo de nieve) encima del cuerpo
    final flakePaint = Paint()
      ..color = const Color(0xFFE0F7FA).withOpacity(0.9 * alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
      canvas.save();
      canvas.rotate((i * pi) / 3);
      
      final path = Path();
      path.moveTo(-14, 0);
      path.lineTo(14, 0);
      path.moveTo(-8, -5); path.lineTo(-4, 0); path.lineTo(-8, 5);
      path.moveTo(8, -5);  path.lineTo(4, 0);  path.lineTo(8, 5);
      
      canvas.drawPath(path, flakePaint);
      canvas.restore();
    }
  }

  void _renderBlackBalloon(Canvas canvas, double alpha) {
    // Dibujar la base idéntica a los globos normales, pero negro/morado oscuro
    _renderBaseBalloon(canvas, const Color(0xFF141821), const Color(0xFF9B59B6), alpha);

    // Dibujar SOLO el ícono de la Bomba adentro del globo
    final bombY = 4.0;
    final bombRadius = size.x * 0.25;

    // Esfera
    canvas.drawCircle(Offset(0, bombY), bombRadius, Paint()..color = const Color(0xFF111111).withOpacity(alpha));
    // Cuello
    canvas.drawRect(
      Rect.fromLTWH(-6, bombY - bombRadius - 6, 12, 6),
      Paint()..color = const Color(0xFF555555).withOpacity(alpha),
    );
    // Brillo 3D
    canvas.drawCircle(Offset(-6, bombY - 6), 5, Paint()..color = Colors.white.withOpacity(0.25 * alpha));
    // Mecha
    final fusePath = Path()
      ..moveTo(0, bombY - bombRadius - 6)
      ..quadraticBezierTo(3, bombY - bombRadius - 12, 8, bombY - bombRadius - 16);
    canvas.drawPath(
      fusePath,
      Paint()
        ..color = const Color(0xFFD9A752).withOpacity(alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    // Chispa
    canvas.drawCircle(Offset(8, bombY - bombRadius - 16), 3, Paint()..color = const Color(0xFFFF9900).withOpacity(alpha));
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (!_active || _tapped) return;
    event.handled = true;
    _tapped = true;
    _active = false;
    onTapped?.call(this);
    removeFromParent();
  }

  void _disappear() {
    _active = false;
    removeFromParent();
  }
  @override
  bool containsLocalPoint(Vector2 point) {
    if (!_active || _tapped) return false;
    return super.containsLocalPoint(point);
  }
}
