import 'dart:math';
import 'package:flutter/material.dart';
import '../models/balloon_type.dart';
import '../utils/constants.dart';
import '../utils/palette.dart';

/// Un widget que dibuja estáticamente un globo usando la misma lógica
/// visual que el BalloonComponent del juego.
/// Ideal para usar en menús y UI donde se requiere transparencia perfecta.
class BalloonWidget extends StatelessWidget {
  final BalloonType type;
  final double width;
  final double height;

  const BalloonWidget({
    super.key,
    required this.type,
    this.width = 60,
    this.height = 75,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _BalloonPainter(type: type),
    );
  }
}

class _BalloonPainter extends CustomPainter {
  final BalloonType type;

  _BalloonPainter({required this.type});

  @override
  void paint(Canvas canvas, Size size) {
    // Calculamos factores de escala para adaptar el dibujo original al tamaño del widget
    final scaleX = size.width / GameConstants.balloonWidth;
    final scaleY = size.height / GameConstants.balloonHeight;

    canvas.save();
    // Trasladamos al centro del widget
    canvas.translate(size.width / 2, size.height / 2);
    // Escalamos para que el globo encaje en el Size del CustomPaint
    canvas.scale(scaleX, scaleY);

    if (type == BalloonType.blue) {
      _renderBlueBalloon(canvas, size);
    } else if (type == BalloonType.black) {
      _renderBlackBalloon(canvas, size);
    } else if (type == BalloonType.clock) {
      _renderClockBalloon(canvas, size);
    } else if (type == BalloonType.armored) {
      _renderArmoredBalloon(canvas, size, 3); // HP=3 for collection screen
    } else {
      _renderBaseBalloon(canvas, size, type.color, type.glowColor);
    }

    canvas.restore();
  }

  void _renderBaseBalloon(Canvas canvas, Size size, Color baseColor, Color glowColor) {
    final paint = Paint()..color = baseColor;
    final glowPaint = Paint()
      ..color = glowColor.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Aura de brillo
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: GameConstants.balloonWidth * 1.2,
        height: GameConstants.balloonHeight * 1.1,
      ),
      glowPaint,
    );

    // Cuerpo del globo
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: GameConstants.balloonWidth,
        height: GameConstants.balloonHeight * 0.85,
      ),
      paint,
    );

    // Brillo especular
    final highlightPaint = Paint()..color = Colors.white.withOpacity(0.5);
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(-8, -12),
        width: 18,
        height: 24,
      ),
      highlightPaint,
    );

    // Nudo del globo
    final knotPaint = Paint()..color = baseColor.withOpacity(0.8);
    final knotY = GameConstants.balloonHeight * 0.42;
    canvas.drawCircle(
      Offset(0, knotY),
      5,
      knotPaint,
    );

    // Hilo del globo estático
    final stringPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final stringPath = Path();
    stringPath.moveTo(0, knotY + 2);
    // Hilo con curva predeterminada
    stringPath.quadraticBezierTo(
      12, knotY + 15,
      -8, knotY + 30,
    );
    canvas.drawPath(stringPath, stringPaint);
  }

  void _renderBlueBalloon(Canvas canvas, Size size) {
    _renderBaseBalloon(canvas, size, const Color(0xFF29B6F6), const Color(0xFF00B4D8));
    final flakePaint = Paint()
      ..color = const Color(0xFFE0F7FA).withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
      canvas.save();
      canvas.rotate((i * pi) / 3);
      final path = Path();
      path.moveTo(-14, 0); path.lineTo(14, 0);
      path.moveTo(-8, -5); path.lineTo(-4, 0); path.lineTo(-8, 5);
      path.moveTo(8, -5);  path.lineTo(4, 0);  path.lineTo(8, 5);
      canvas.drawPath(path, flakePaint);
      canvas.restore();
    }
  }

  void _renderBlackBalloon(Canvas canvas, Size size) {
    _renderBaseBalloon(canvas, size, Palette.balloonBlack, Palette.balloonBlackGlow);
    final bombY = 4.0;
    final bombRadius = GameConstants.balloonWidth * 0.25;

    canvas.drawCircle(Offset(0, bombY), bombRadius, Paint()..color = const Color(0xFF111111));
    canvas.drawRect(
      Rect.fromLTWH(-6, bombY - bombRadius - 6, 12, 6),
      Paint()..color = const Color(0xFF555555),
    );
    canvas.drawCircle(Offset(-6, bombY - 6), 5, Paint()..color = Colors.white.withOpacity(0.25));
    final fusePath = Path()
      ..moveTo(0, bombY - bombRadius - 6)
      ..quadraticBezierTo(3, bombY - bombRadius - 12, 8, bombY - bombRadius - 16);
    canvas.drawPath(
      fusePath,
      Paint()
        ..color = const Color(0xFFD9A752)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(Offset(8, bombY - bombRadius - 16), 3, Paint()..color = const Color(0xFFFF9900));
  }

  void _renderClockBalloon(Canvas canvas, Size size) {
    _renderBaseBalloon(canvas, size, Palette.balloonClock, Palette.balloonClockGlow);
    final clockY = 4.0;
    final clockRadius = GameConstants.balloonWidth * 0.22;

    canvas.drawCircle(Offset(0, clockY), clockRadius, Paint()..color = const Color(0xFFFFFDE7));
    canvas.drawCircle(
      Offset(0, clockY),
      clockRadius,
      Paint()
        ..color = const Color(0xFFFBC02D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );
    final hourHand = Path()..moveTo(0, clockY)..lineTo(clockRadius * 0.4, clockY + clockRadius * 0.2);
    canvas.drawPath(hourHand, Paint()..color = const Color(0xFF333333)..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeCap = StrokeCap.round);
    
    // Static minute hand
    final minHand = Path()..moveTo(0, clockY)..lineTo(0, clockY - clockRadius * 0.7);
    canvas.drawPath(minHand, Paint()..color = const Color(0xFFD32F2F)..style = PaintingStyle.stroke..strokeWidth = 2.0..strokeCap = StrokeCap.round);

    canvas.drawCircle(Offset(0, clockY), 2.5, Paint()..color = const Color(0xFF333333));
  }

  void _renderArmoredBalloon(Canvas canvas, Size size, int hp) {
    if (hp == 1) {
      // Capa 3: Globo común (Rojo)
      _renderBaseBalloon(canvas, size, Palette.balloonRed, Palette.balloonRedGlow);
      return;
    }

    final isPremium = hp == 3;
    final baseColor = isPremium ? Palette.armoredPremium : Palette.armoredDamaged;
    final glowColor = isPremium ? Palette.armoredPremiumGlow : Palette.armoredDamagedGlow;

    // Dibujar base metálica
    _renderBaseBalloon(canvas, size, baseColor, glowColor);

    // Dibujar escudo de protección en el centro
    final shieldPaint = Paint()
      ..color = isPremium ? const Color(0xFFFBC02D).withOpacity(0.9) : const Color(0xFF9E9E9E).withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final shieldBorderPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final shieldPath = Path()
      ..moveTo(-14, -12)
      ..lineTo(14, -12)
      ..lineTo(14, 2)
      ..quadraticBezierTo(14, 16, 0, 22)
      ..quadraticBezierTo(-14, 16, -14, 2)
      ..close();

    canvas.drawPath(shieldPath, shieldPaint);
    canvas.drawPath(shieldPath, shieldBorderPaint);

    if (isPremium) {
      // Cruz protectora en el centro del escudo
      final crossPaint = Paint()
        ..color = Colors.white.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(0, -6), const Offset(0, 8), crossPaint);
      canvas.drawLine(const Offset(-7, 1), const Offset(7, 1), crossPaint);
    } else {
      // Grietas en el escudo por el daño
      final crackPaint = Paint()
        ..color = Colors.black.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      final crackPath = Path()
        ..moveTo(-8, -12)
        ..lineTo(-2, -2)
        ..lineTo(-6, 6)
        ..lineTo(2, 16);
      canvas.drawPath(crackPath, crackPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BalloonPainter oldDelegate) {
    return oldDelegate.type != type;
  }
}
