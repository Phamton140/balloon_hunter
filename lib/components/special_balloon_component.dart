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
    
    // Solo aplicamos la animación de pulso, no distorsionamos las proporciones X/Y
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
    // Para que las proporciones sean uniformes a los PNG:
    // El cuerpo ocupa el ancho total (size.x) y un 82% del alto (size.y)
    final bodyWidth = size.x;
    final bodyHeight = size.y * 0.82;
    // Ajustamos el centro un poco hacia arriba para dejar espacio al nudo
    final bodyCenterY = -size.y * 0.05;
    
    final rect = Rect.fromCenter(
      center: Offset(0, bodyCenterY), 
      width: bodyWidth, 
      height: bodyHeight
    );

    // Azul vibrante pero manteniendo el tono hielo (celeste intenso)
    canvas.drawOval(
      rect,
      Paint()
        ..color = const Color(0xFF29B6F6).withOpacity(0.9 * alpha) // Celeste hielo brillante
        ..style = PaintingStyle.fill,
    );
    canvas.drawOval(
      rect,
      Paint()
        ..color = const Color(0xFF0277BD).withOpacity(alpha) // Borde azul claro
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Copo de Nieve Central (Blanco/Celeste para resaltar en el fondo oscuro)
    final flakePaint = Paint()
      ..color = const Color(0xFFE0F7FA).withOpacity(0.9 * alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final flakeY = bodyCenterY;
    for (int i = 0; i < 3; i++) {
      canvas.save();
      canvas.translate(0, flakeY);
      canvas.rotate((i * pi) / 3);
      
      final path = Path();
      // Línea principal
      path.moveTo(-14, 0);
      path.lineTo(14, 0);
      // Ramas
      path.moveTo(-8, -5); path.lineTo(-4, 0); path.lineTo(-8, 5);
      path.moveTo(8, -5);  path.lineTo(4, 0);  path.lineTo(8, 5);
      
      canvas.drawPath(path, flakePaint);
      canvas.restore();
    }

    // Reflejo cristalino
    canvas.save();
    canvas.translate(-size.x * 0.25, bodyCenterY - size.y * 0.2);
    canvas.rotate(-pi / 6);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: size.x * 0.15, height: size.y * 0.3),
      Paint()..color = Colors.white.withOpacity(0.4 * alpha),
    );
    canvas.restore();

    // Nudo
    final knotY = bodyCenterY + (bodyHeight / 2);
    final knotPath = Path()
      ..moveTo(-5, knotY + 5)
      ..lineTo(5, knotY + 5)
      ..lineTo(0, knotY)
      ..close();
    canvas.drawPath(knotPath, Paint()..color = const Color(0xFF084298).withOpacity(alpha));

    // Hilo animado
    final stringPath = Path()
      ..moveTo(0, knotY + 2)
      ..quadraticBezierTo(sin(_pulseTime * 2) * 10, knotY + 15, -sin(_pulseTime * 2) * 5, knotY + 35);
    
    canvas.drawPath(
      stringPath,
      Paint()
        ..color = Colors.white.withOpacity(0.8 * alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _renderBlackBalloon(Canvas canvas, double alpha) {
    final bodyWidth = size.x;
    final bodyHeight = size.y * 0.82;
    final bodyCenterY = -size.y * 0.05;

    // CAPA 1: Cuerpo del Globo Negro
    final rect = Rect.fromCenter(center: Offset(0, bodyCenterY), width: bodyWidth, height: bodyHeight);
    canvas.drawOval(
      rect,
      Paint()
        ..color = const Color(0xFF141821).withOpacity(0.9 * alpha)
        ..style = PaintingStyle.fill,
    );
    canvas.drawOval(
      rect,
      Paint()
        ..color = const Color(0xFF3A4454).withOpacity(alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // CAPA 2: Bomba Clásica en el Interior
    final bombY = bodyCenterY + 4.0;
    final bombRadius = size.x * 0.3;

    // Esfera de la bomba
    canvas.drawCircle(Offset(0, bombY), bombRadius, Paint()..color = const Color(0xFF111111).withOpacity(alpha));

    // Cuello metálico
    canvas.drawRect(
      Rect.fromLTWH(-6, bombY - bombRadius - 6, 12, 6),
      Paint()..color = const Color(0xFF555555).withOpacity(alpha),
    );

    // Brillo 3D en la bomba
    canvas.drawCircle(Offset(-6, bombY - 6), 5, Paint()..color = Colors.white.withOpacity(0.25 * alpha));

    // Mecha saliendo de la bomba
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

    // Chispa encendida de la bomba interior
    canvas.drawCircle(Offset(8, bombY - bombRadius - 16), 3, Paint()..color = const Color(0xFFFF9900).withOpacity(alpha));

    // Brillo exterior del globo (reflejo sutil)
    canvas.save();
    canvas.translate(-size.x * 0.25, bodyCenterY - size.y * 0.2);
    canvas.rotate(-pi / 6);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: size.x * 0.15, height: size.y * 0.25),
      Paint()..color = Colors.white.withOpacity(0.15 * alpha),
    );
    canvas.restore();

    // Nudo del globo
    final knotY = bodyCenterY + (bodyHeight / 2);
    final knotPath = Path()
      ..moveTo(-5, knotY + 5)
      ..lineTo(5, knotY + 5)
      ..lineTo(0, knotY)
      ..close();
    canvas.drawPath(knotPath, Paint()..color = const Color(0xFF141821).withOpacity(alpha));

    // CAPA 3: Hilo actuando como Mecha Principal animado
    final stringEndX = -sin(_pulseTime * 2) * 5;
    final stringEndY = knotY + 35.0;
    
    final stringPath = Path()
      ..moveTo(0, knotY + 2)
      ..quadraticBezierTo(sin(_pulseTime * 2) * 10, knotY + 15, stringEndX, stringEndY);
      
    canvas.drawPath(
      stringPath,
      Paint()
        ..color = const Color(0xFFF5C542).withOpacity(alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Chispa en la punta del hilo
    canvas.drawCircle(Offset(stringEndX, stringEndY), 4.5, Paint()..color = const Color(0xFFFF4500).withOpacity(alpha));
    canvas.drawCircle(Offset(stringEndX, stringEndY), 2.5, Paint()..color = const Color(0xFFFFEA00).withOpacity(alpha));
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
