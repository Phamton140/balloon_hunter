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
    
    // Escalamos el canvas para que coincida con las proporciones del diseño JS (110x150)
    // respecto a las dimensiones actuales del componente.
    final scaleX = size.x / 110.0;
    final scaleY = size.y / 150.0;
    canvas.scale(scaleX * _scaleAnim, scaleY * _scaleAnim);

    final alpha = 1.0;

    if (_type == BalloonType.blue) {
      _renderBlueBalloon(canvas, alpha);
    } else {
      _renderBlackBalloon(canvas, alpha);
    }

    canvas.restore();
  }

  void _renderBlueBalloon(Canvas canvas, double alpha) {
    final rx = 55.0;
    final ry = 75.0;

    // Cuerpo del globo Helado
    final rect = Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2);
    canvas.drawOval(
      rect,
      Paint()
        ..color = const Color(0xFFB4EBFF).withOpacity(0.75 * alpha)
        ..style = PaintingStyle.fill,
    );
    canvas.drawOval(
      rect,
      Paint()
        ..color = const Color(0xFFA6E3E9).withOpacity(alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Copo de Nieve Central
    final flakePaint = Paint()
      ..color = const Color(0xFF4682B4).withOpacity(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
      canvas.save();
      canvas.rotate((i * pi) / 3);
      
      final path = Path();
      // Línea principal
      path.moveTo(-22, 0);
      path.lineTo(22, 0);
      // Ramas
      path.moveTo(-12, -8); path.lineTo(-6, 0); path.lineTo(-12, 8);
      path.moveTo(12, -8);  path.lineTo(6, 0);  path.lineTo(12, 8);
      
      canvas.drawPath(path, flakePaint);
      canvas.restore();
    }

    // Reflejo cristalino
    canvas.save();
    canvas.translate(-25, -30);
    canvas.rotate(-pi / 6);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 20, height: 44),
      Paint()..color = Colors.white.withOpacity(0.45 * alpha),
    );
    canvas.restore();

    // Nudo helado
    final knotY = ry;
    final knotPath = Path()
      ..moveTo(-8, knotY + 6)
      ..lineTo(8, knotY + 6)
      ..lineTo(0, knotY)
      ..close();
    canvas.drawPath(knotPath, Paint()..color = const Color(0xFF71C7EC).withOpacity(alpha));

    // Hilo Blanco/Helado animado
    final stringPath = Path()
      ..moveTo(0, knotY + 3)
      ..quadraticBezierTo(sin(_pulseTime * 2) * 15, knotY + 30, -sin(_pulseTime * 2) * 5, knotY + 60);
    
    canvas.drawPath(
      stringPath,
      Paint()
        ..color = Colors.white.withOpacity(alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _renderBlackBalloon(Canvas canvas, double alpha) {
    final rx = 55.0;
    final ry = 75.0;

    // CAPA 1: Cuerpo del Globo Negro
    final rect = Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2);
    canvas.drawOval(
      rect,
      Paint()
        ..color = const Color(0xFF141821).withOpacity(0.85 * alpha)
        ..style = PaintingStyle.fill,
    );
    canvas.drawOval(
      rect,
      Paint()
        ..color = const Color(0xFF3A4454).withOpacity(alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // CAPA 2: Bomba Clásica en el Interior
    final bombY = 10.0;
    final bombRadius = 32.0;

    // Esfera de la bomba
    canvas.drawCircle(Offset(0, bombY), bombRadius, Paint()..color = const Color(0xFF111111).withOpacity(alpha));

    // Cuello metálico
    canvas.drawRect(
      Rect.fromLTWH(-10, bombY - bombRadius - 8, 20, 8),
      Paint()..color = const Color(0xFF555555).withOpacity(alpha),
    );

    // Brillo 3D en la bomba
    canvas.drawCircle(Offset(-10, bombY - 10), 8, Paint()..color = Colors.white.withOpacity(0.25 * alpha));

    // Mecha saliendo de la bomba
    final fusePath = Path()
      ..moveTo(0, bombY - bombRadius - 8)
      ..quadraticBezierTo(5, bombY - bombRadius - 20, 12, bombY - bombRadius - 25);
    canvas.drawPath(
      fusePath,
      Paint()
        ..color = const Color(0xFFD9A752).withOpacity(alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Chispa encendida
    canvas.drawCircle(Offset(12, bombY - bombRadius - 25), 5, Paint()..color = const Color(0xFFFF9900).withOpacity(alpha));

    // Brillo exterior del globo (reflejo sutil)
    canvas.save();
    canvas.translate(-25, -30);
    canvas.rotate(-pi / 6);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 20, height: 40),
      Paint()..color = Colors.white.withOpacity(0.15 * alpha),
    );
    canvas.restore();

    // Nudo del globo
    final knotY = ry;
    final knotPath = Path()
      ..moveTo(-8, knotY + 6)
      ..lineTo(8, knotY + 6)
      ..lineTo(0, knotY)
      ..close();
    canvas.drawPath(knotPath, Paint()..color = const Color(0xFF141821).withOpacity(alpha));

    // CAPA 3: Hilo actuando como Mecha Principal animado
    final stringEndX = -sin(_pulseTime * 2) * 5;
    final stringEndY = knotY + 60.0;
    
    final stringPath = Path()
      ..moveTo(0, knotY + 3)
      ..quadraticBezierTo(sin(_pulseTime * 2) * 15, knotY + 30, stringEndX, stringEndY);
      
    canvas.drawPath(
      stringPath,
      Paint()
        ..color = const Color(0xFFF5C542).withOpacity(alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Chispa en la punta del hilo
    canvas.drawCircle(Offset(stringEndX, stringEndY), 7, Paint()..color = const Color(0xFFFF4500).withOpacity(alpha));
    canvas.drawCircle(Offset(stringEndX, stringEndY), 3.5, Paint()..color = const Color(0xFFFFEA00).withOpacity(alpha));
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
