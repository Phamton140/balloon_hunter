import 'dart:math';
import 'package:flutter/material.dart';
import '../models/balloon_type.dart';
import '../utils/constants.dart';
import '../utils/palette.dart';

/// Un widget que dibuja un globo usando la misma lógica visual que el juego,
/// incluyendo mecha con chispa incandescente animada para el globo bomba (black).
class BalloonWidget extends StatefulWidget {
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
  State<BalloonWidget> createState() => _BalloonWidgetState();
}

class _BalloonWidgetState extends State<BalloonWidget> with SingleTickerProviderStateMixin {
  late AnimationController _sparkController;

  @override
  void initState() {
    super.initState();
    // Controlador en bucle continuo para animar el fuego y las chispas de la mecha
    _sparkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();
  }

  @override
  void dispose() {
    _sparkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sparkController,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.width, widget.height),
          painter: _BalloonPainter(
            type: widget.type,
            animationValue: _sparkController.value,
          ),
        );
      },
    );
  }
}

class _BalloonPainter extends CustomPainter {
  final BalloonType type;
  final double animationValue;

  _BalloonPainter({
    required this.type,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / GameConstants.balloonWidth;
    final scaleY = size.height / GameConstants.balloonHeight;

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scaleX, scaleY);

    if (type == BalloonType.blue) {
      _renderBlueBalloon(canvas, size);
    } else if (type == BalloonType.black) {
      _renderBlackBalloon(canvas, size);
    } else if (type == BalloonType.clock) {
      _renderClockBalloon(canvas, size);
    } else if (type == BalloonType.armored) {
      _renderArmoredBalloon(canvas, size, 3);
    } else {
      _renderBaseBalloon(canvas, size, type.color, type.glowColor, drawDefaultString: true);
    }

    canvas.restore();
  }

  void _renderBaseBalloon(
    Canvas canvas,
    Size size,
    Color baseColor,
    Color glowColor, {
    bool drawDefaultString = true,
  }) {
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
    final highlightPaint = Paint()..color = Colors.white.withOpacity(0.35);
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(-8, -12),
        width: 18,
        height: 24,
      ),
      highlightPaint,
    );

    // Nudo del globo
    final knotPaint = Paint()..color = baseColor.withOpacity(0.9);
    final knotY = GameConstants.balloonHeight * 0.42;
    canvas.drawCircle(
      Offset(0, knotY),
      5,
      knotPaint,
    );

    // Hilo estándar (solo para globos normales)
    if (drawDefaultString) {
      final stringPaint = Paint()
        ..color = Colors.white.withOpacity(0.4)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      final stringPath = Path();
      stringPath.moveTo(0, knotY + 2);
      stringPath.quadraticBezierTo(
        12, knotY + 15,
        -8, knotY + 30,
      );
      canvas.drawPath(stringPath, stringPaint);
    }
  }

  void _renderBlackBalloon(Canvas canvas, Size size) {
    // 1. Cuerpo del globo negro (sin hilo común)
    _renderBaseBalloon(
      canvas,
      size,
      Palette.balloonBlack,
      Palette.balloonBlackGlow,
      drawDefaultString: false,
    );

    final knotY = GameConstants.balloonHeight * 0.42;

    // 2. Casquillo metálico en la base del nudo
    final capPaint = Paint()..color = const Color(0xFF8D6E63);
    canvas.drawRect(
      Rect.fromCenter(center: Offset(0, knotY + 1), width: 8, height: 3),
      capPaint,
    );

    // 3. Mecha de cuerda
    final fusePath = Path();
    fusePath.moveTo(0, knotY + 2);
    fusePath.quadraticBezierTo(
      10, knotY + 12,
      -4, knotY + 24,
    );

    final fusePaint = Paint()
      ..color = const Color(0xFF8D7B68)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(fusePath, fusePaint);

    // 4. Ubicación de la mecha encendida (Ajustada exactamente a la punta exterior del hilo)
    final sparkTip = Offset(-4, knotY + 24);

    // 5. EFECTO DE FUEGO Y CHISPAS REFORZADO
    final pulse = sin(animationValue * pi * 2);

    // Aura caliente
    final glowPaint = Paint()
      ..color = const Color(0xFFFF3300).withOpacity(0.5 + (0.3 * pulse))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(sparkTip, 14, glowPaint);

    // Incandescencia de la cuerda
    final emberPaint = Paint()
      ..color = const Color(0xFFFF5500)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(sparkTip, 7 + (1.5 * pulse), emberPaint);

    // Llama en 3 capas
    final outerFlame = Paint()..color = const Color(0xFFFF9100);
    final innerFlame = Paint()..color = const Color(0xFFFFFF00);
    final coreFlame = Paint()..color = Colors.white;

    canvas.drawCircle(sparkTip, 5 + (1.0 * pulse), outerFlame);
    canvas.drawCircle(sparkTip, 3 + (0.5 * pulse), innerFlame);
    canvas.drawCircle(sparkTip, 1.5, coreFlame);

    // Chispas volantes
    final sparkPaint = Paint()..strokeCap = StrokeCap.round;

    for (int i = 0; i < 7; i++) {
      final progress = ((animationValue + (i / 7.0)) % 1.0);
      final angle = (i * (pi / 3.5)) + (animationValue * pi);
      final distance = 4.0 + (progress * 14.0);

      final sparkX = sparkTip.dx + cos(angle) * distance;
      final sparkY = sparkTip.dy + sin(angle) * distance;
      final sparkSize = (1.0 - progress) * 2.8;

      if (sparkSize > 0.3) {
        sparkPaint.color = i.isEven ? const Color(0xFFFFEA00) : const Color(0xFFFF3D00);
        canvas.drawCircle(Offset(sparkX, sparkY), sparkSize, sparkPaint);
      }
    }
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
    
    final minHand = Path()..moveTo(0, clockY)..lineTo(0, clockY - clockRadius * 0.7);
    canvas.drawPath(minHand, Paint()..color = const Color(0xFFD32F2F)..style = PaintingStyle.stroke..strokeWidth = 2.0..strokeCap = StrokeCap.round);

    canvas.drawCircle(Offset(0, clockY), 2.5, Paint()..color = const Color(0xFF333333));
  }

  void _renderArmoredBalloon(Canvas canvas, Size size, int hp) {
    if (hp == 1) {
      _renderBaseBalloon(canvas, size, Palette.balloonRed, Palette.balloonRedGlow);
      return;
    }

    final isPremium = hp == 3;
    final baseColor = isPremium ? Palette.armoredPremium : Palette.armoredDamaged;
    final glowColor = isPremium ? Palette.armoredPremiumGlow : Palette.armoredDamagedGlow;

    _renderBaseBalloon(canvas, size, baseColor, glowColor);

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
      final crossPaint = Paint()
        ..color = Colors.white.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(0, -6), const Offset(0, 8), crossPaint);
      canvas.drawLine(const Offset(-7, 1), const Offset(7, 1), crossPaint);
    } else {
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
    return oldDelegate.type != type || oldDelegate.animationValue != animationValue;
  }
}