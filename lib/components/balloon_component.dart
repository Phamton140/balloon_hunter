// lib/components/balloon_component.dart
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../models/balloon_type.dart';
import '../models/game_state.dart';
import '../utils/constants.dart';
import '../utils/palette.dart';
import '../balloon_hunter_game.dart';

/// Representa un globo estándar en el juego.
/// Al ser tocado notifica al juego para procesar el impacto.
/// Compatible con Object Pooling: usa configure() para resetear estado.
class BalloonComponent extends PositionComponent
    with TapCallbacks, HasGameReference<BalloonHunterGame> {
  // -- Tipo y propiedades --
  BalloonType _type = BalloonType.yellow;
  BalloonType get balloonType => _type;

  // -- Movimiento --
  double _speed = 0.0;
  double _baseX = 0.0;
  
  // -- Animación (viento y chispas) --
  double _oscillationTime = 0.0;
  double _oscillationAmplitude = 0.0;
  double _oscillationFreq = 0.0;
  double _oscillationPhase = 0.0;
  double _sparkAnimationTime = 0.0;

  // -- Pool (puede ser null si no se usa pool) --
  dynamic _pool;

  // -- Estado --
  bool _active = false;
  bool get isActive => _active;
  bool _tapped = false;

  // -- Callbacks --
  void Function(BalloonComponent)? onTapped;
  void Function(BalloonComponent)? onEscaped;

  final Random _random = Random();

  BalloonComponent() {
    width = GameConstants.balloonWidth;
    height = GameConstants.balloonHeight;
    anchor = Anchor.center;
  }

  /// Configura el globo antes de añadirlo al juego (reutilizable con pool)
  void configure({
    required BalloonType type,
    required double x,
    required double y,
    dynamic pool,
    double speedMultiplier = 1.0,
    double slowMultiplier = 1.0,
  }) {
    _type = type;
    _pool = pool;
    _tapped = false;
    _active = true;
    _oscillationTime = _random.nextDouble() * 2 * pi;
    _sparkAnimationTime = _random.nextDouble();

    // Variación aleatoria de velocidad ±10%
    final variation = GameConstants.speedVariationMin +
        _random.nextDouble() *
            (GameConstants.speedVariationMax - GameConstants.speedVariationMin);

    _speed = type.baseSpeed * speedMultiplier * variation * slowMultiplier;

    // Parámetros de oscilación únicos por instancia
    _oscillationAmplitude = GameConstants.oscillationAmplitudeMin +
        _random.nextDouble() *
            (GameConstants.oscillationAmplitudeMax -
                GameConstants.oscillationAmplitudeMin);
    _oscillationFreq = GameConstants.oscillationFreqMin +
        _random.nextDouble() *
            (GameConstants.oscillationFreqMax - GameConstants.oscillationFreqMin);
    _oscillationPhase = _random.nextDouble() * 2 * pi;

    position.x = x;
    position.y = y;
    _baseX = x;
  }

  @override
  void update(double dt) {
    if (!_active) return;
    if (game.gameManager.state != GameState.playing || game.gameManager.isFrozen) return;
    super.update(dt);

    _oscillationTime += dt;
    _sparkAnimationTime = (_sparkAnimationTime + dt * 2.5) % 1.0; // Velocidad de giro/pulso de la mecha

    // Oscilación horizontal (simulación de viento)
    final dx = sin(_oscillationTime * _oscillationFreq + _oscillationPhase) *
        _oscillationAmplitude;
    position.x = _baseX + dx;

    // Ascenso vertical
    position.y -= _speed * dt;

    // Verificar si escapó por la parte superior (cuando entra por completo al HUD)
    if (position.y + (GameConstants.balloonHeight / 2) < GameConstants.hudHeight) {
      _onEscaped();
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_active) return;

    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);

    if (_type == BalloonType.blue) {
      _renderBlueBalloon(canvas);
    } else if (_type == BalloonType.black) {
      _renderBlackBalloon(canvas);
    } else if (_type == BalloonType.clock) {
      _renderClockBalloon(canvas);
    } else if (_type == BalloonType.armored) {
      _renderArmoredBalloon(canvas, 3);
    } else {
      _renderBaseBalloon(canvas, _type.color, _type.glowColor, drawDefaultString: true);
    }

    canvas.restore();
  }

  // ---------------------------------------------------------------------------
  // MÉTODOS DE RENDERIZADO PROGRAMÁTICO
  // ---------------------------------------------------------------------------

  void _renderBaseBalloon(
    Canvas canvas,
    Color baseColor,
    Color glowColor, {
    bool drawDefaultString = true,
  }) {
    final paint = Paint()..color = baseColor;
    final glowPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.4)
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
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5);
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(-8, -12),
        width: 18,
        height: 24,
      ),
      highlightPaint,
    );

    // Nudo del globo
    final knotPaint = Paint()..color = baseColor.withValues(alpha: 0.8);
    final knotY = GameConstants.balloonHeight * 0.42;
    canvas.drawCircle(
      Offset(0, knotY),
      5,
      knotPaint,
    );

    // Hilo estándar (animado con el viento)
    if (drawDefaultString) {
      final stringPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      final stringPath = Path();
      stringPath.moveTo(0, knotY + 2);
      stringPath.quadraticBezierTo(
        sin(_oscillationTime * 3) * 12, knotY + 15,
        -sin(_oscillationTime * 3) * 8, knotY + 30,
      );
      canvas.drawPath(stringPath, stringPaint);
    }
  }

  void _renderBlackBalloon(Canvas canvas) {
    // 1. Cuerpo del globo negro
    _renderBaseBalloon(
      canvas,
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

    // 3. Mecha de cuerda (oscila con el viento)
    final fusePath = Path();
    fusePath.moveTo(0, knotY + 2);

    final curveX1 = 10 + sin(_oscillationTime * 3) * 4;
    final curveX2 = -4 + sin(_oscillationTime * 3) * 2;

    fusePath.quadraticBezierTo(
      curveX1, knotY + 12,
      curveX2, knotY + 24,
    );

    final fusePaint = Paint()
      ..color = const Color(0xFF8D7B68)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(fusePath, fusePaint);

    // 4. Ubicación de la mecha encendida (en el extremo exterior del hilo)
    final sparkTip = Offset(curveX2, knotY + 24);

    // 5. EFECTO DE FUEGO Y CHISPAS ANIMADO
    final pulse = sin(_sparkAnimationTime * pi * 2);

    // Aura caliente
    final glowPaint = Paint()
      ..color = const Color(0xFFFF3300).withValues(alpha: 0.5 + (0.3 * pulse))
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

    // Chispas volantes que giran continuamente alrededor de la punta
    final sparkPaint = Paint()..strokeCap = StrokeCap.round;

    for (int i = 0; i < 7; i++) {
      final progress = ((_sparkAnimationTime + (i / 7.0)) % 1.0);
      final angle = (i * (pi / 3.5)) + (_sparkAnimationTime * pi);
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

  void _renderBlueBalloon(Canvas canvas) {
    _renderBaseBalloon(canvas, const Color(0xFF29B6F6), const Color(0xFF00B4D8));
    final flakePaint = Paint()
      ..color = const Color(0xFFE0F7FA).withValues(alpha: 0.9)
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

  void _renderClockBalloon(Canvas canvas) {
    _renderBaseBalloon(canvas, Palette.balloonClock, Palette.balloonClockGlow);
    const clockY = 4.0;
    final clockRadius = GameConstants.balloonWidth * 0.22;

    canvas.drawCircle(const Offset(0, clockY), clockRadius, Paint()..color = const Color(0xFFFFFDE7));
    canvas.drawCircle(
      const Offset(0, clockY),
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

    canvas.drawCircle(const Offset(0, clockY), 2.5, Paint()..color = const Color(0xFF333333));
  }

  void _renderArmoredBalloon(Canvas canvas, int hp) {
    if (hp == 1) {
      _renderBaseBalloon(canvas, Palette.balloonRed, Palette.balloonRedGlow);
      return;
    }

    final isPremium = hp == 3;
    final baseColor = isPremium ? Palette.armoredPremium : Palette.armoredDamaged;
    final glowColor = isPremium ? Palette.armoredPremiumGlow : Palette.armoredDamagedGlow;

    _renderBaseBalloon(canvas, baseColor, glowColor);

    final shieldPaint = Paint()
      ..color = isPremium ? const Color(0xFFFBC02D).withValues(alpha: 0.9) : const Color(0xFF9E9E9E).withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final shieldBorderPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
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
        ..color = Colors.white.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(0, -6), const Offset(0, 8), crossPaint);
      canvas.drawLine(const Offset(-7, 1), const Offset(7, 1), crossPaint);
    } else {
      final crackPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.6)
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
  void onTapDown(TapDownEvent event) {
    if (!_active || _tapped) return;
    _tapped = true;
    onTapped?.call(this);
  }

  /// Explota el globo y lo devuelve al pool
  void explodeAndReturn() {
    if (!_active) return;
    _active = false;
    _pool?.release(this);
  }

  void _onEscaped() {
    if (!_active) return;
    _active = false;
    onEscaped?.call(this);
    _pool?.release(this);
  }

  /// Actualiza la velocidad en tiempo real (para slow motion)
  void applySlowMultiplier(double multiplier) {
    _speed *= multiplier;
  }
  
  @override
  bool containsLocalPoint(Vector2 point) {
    if (!_active || _tapped) return false;
    return super.containsLocalPoint(point);
  }
}