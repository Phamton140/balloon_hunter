import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../models/balloon_type.dart';
import '../models/game_state.dart';
import '../utils/constants.dart';
import '../utils/palette.dart';
import '../balloon_hunter_game.dart';

/// Componente de globo blindado.
/// Requiere 3 toques para ser destruido y cambia visualmente por capa.
class ArmoredBalloonComponent extends PositionComponent
    with TapCallbacks, HasGameReference<BalloonHunterGame> {
// Estado interno
  int _hp = 3;
  int get hp => _hp;
  set hp(int value) {
    _hp = value.clamp(0, 3); // Clamp entre 0 y 3
  }

// Propiedades
  final BalloonType _type = BalloonType.armored;
  BalloonType get balloonType => _type;
  
  double _speed = 0.0;
  set speed(double value) {
    _speed = value.clamp(0.0, double.infinity);
  }
  double _baseX = 0.0;
  
  // Animación (viento)
  double _oscillationTime = 0.0;
  double _oscillationAmplitude = 0.0;
  double _oscillationFreq = 0.0;
  double _oscillationPhase = 0.0;
  
  // Efecto de impacto visual
  double _hitFlashTime = 0.0;

  // Pool
  dynamic _pool;

  // Estado
  bool _active = false;
  bool get isActive => _active;
  bool _tapped = false; // Solo para prevenir toques repetidos en un solo tap

  // Callbacks
  void Function(ArmoredBalloonComponent)? onTapped;
  void Function(ArmoredBalloonComponent)? onEscaped;

  final Random _random = Random();

  ArmoredBalloonComponent() {
    width = GameConstants.balloonWidth;
    height = GameConstants.balloonHeight;
    anchor = Anchor.center;
  }

  /// Configura el globo antes de añadirlo
  void configure({
    required double x,
    required double y,
    dynamic pool,
    double speedMultiplier = 1.0,
    double slowMultiplier = 1.0,
  }) {
    _hp = 3;
    _pool = pool;
    _active = true;
    _tapped = false;
    _hitFlashTime = 0.0;
    _oscillationTime = _random.nextDouble() * 2 * pi;

    final variation = GameConstants.speedVariationMin +
        _random.nextDouble() *
            (GameConstants.speedVariationMax - GameConstants.speedVariationMin);

    _speed = _type.baseSpeed * speedMultiplier * variation * slowMultiplier;

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

    if (_hitFlashTime > 0) {
      _hitFlashTime -= dt;
    }

    _oscillationTime += dt;
    final dx = sin(_oscillationTime * _oscillationFreq + _oscillationPhase) *
        _oscillationAmplitude;
    position.x = _baseX + dx;
    position.y -= _speed * dt;

    if (position.y + (GameConstants.balloonHeight / 2) < GameConstants.hudHeight) {
      _onEscaped();
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_active) return;

    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);

    if (_hitFlashTime > 0) {
      // Efecto de sacudida rápido al ser golpeado
      final shake = sin(_hitFlashTime * 50) * 2;
      canvas.translate(shake, 0);
    }

    _renderArmoredBalloon(canvas);

    canvas.restore();
  }

  void _renderBaseBalloon(Canvas canvas, Color baseColor, Color glowColor) {
    final paint = Paint()..color = baseColor;
    final glowPaint = Paint()
      ..color = glowColor.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: GameConstants.balloonWidth * 1.2,
        height: GameConstants.balloonHeight * 1.1,
      ),
      glowPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: GameConstants.balloonWidth,
        height: GameConstants.balloonHeight * 0.85,
      ),
      paint,
    );

    final highlightPaint = Paint()..color = Colors.white.withOpacity(0.5);
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(-8, -12),
        width: 18,
        height: 24,
      ),
      highlightPaint,
    );

    final knotPaint = Paint()..color = baseColor.withOpacity(0.8);
    final knotY = GameConstants.balloonHeight * 0.42;
    canvas.drawCircle(Offset(0, knotY), 5, knotPaint);

    final stringPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final stringPath = Path();
    stringPath.moveTo(0, knotY + 2);
    stringPath.quadraticBezierTo(
      sin(_oscillationTime * 3) * 12, knotY + 15,
      -sin(_oscillationTime * 3) * 8, knotY + 30
    );
    canvas.drawPath(stringPath, stringPaint);
  }

  void _renderArmoredBalloon(Canvas canvas) {
    // Siempre usamos colores morados (el globo mantiene su color principal)
    final ispremium = _hp == 3;
    final baseColor = ispremium ? Palette.armoredPremium : Palette.armoredDamaged;
    final glowColor = ispremium ? Palette.armoredPremiumGlow : Palette.armoredDamagedGlow;

    _renderBaseBalloon(canvas, baseColor, glowColor);

    // Dibujar escudo de protección en el centro (siempre visible, con estado según hp)
    final shieldPaint = Paint()
      ..color = ispremium ? const Color(0xFFFBC02D).withOpacity(0.9) : const Color(0xFF8E44AD).withOpacity(0.8)
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

    // Mostrar estado del escudo según golpes recibidos
    if (ispremium) {
      // Cruz protectora en el centro del escudo (solo cuando tiene los 3 escudos)
      final crossPaint = Paint()
        ..color = Colors.white.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(0, -6), const Offset(0, 8), crossPaint);
      canvas.drawLine(const Offset(-7, 1), const Offset(7, 1), crossPaint);
    } else {
      // Grietas en el escudo por el daño (siempre visibles cuando hp < 3)
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
      // Siempre mostrar al menos una grieta para mostrar que ha recibido daño
      if (_hp <= 2) {
        final crackPaint2 = Paint()
          ..color = Colors.black.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        final crackPath2 = Path()
          ..moveTo(-4, -8)
          ..lineTo(4, -8);
        canvas.drawPath(crackPath2, crackPaint2);
      }
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (!_active || _tapped) return;
    _tapped = true;
    onTapped?.call(this);
    // Removemos la bandera _tapped después de un breve delay si el globo sobrevive
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_active) _tapped = false;
    });
  }

  /// Reduce HP y actualiza velocidad progresivamente
  /// Velocidad: 1er toque = amarillo, 2to = verde, 3to = rojo (siempre color morado)
  void takeHit() {
    _hp--;
    _hitFlashTime = 0.2; // Efecto de parpadeo/sacudida

    // Actualizar velocidad según número de toques recibidos
    final variation = GameConstants.speedVariationMin +
        _random.nextDouble() *
            (GameConstants.speedVariationMax - GameConstants.speedVariationMin);

    switch (_hp) {
      case 2:
        // 1er impacto: velocidad amarillo (80.0)
        _speed = 80.0 * variation;
        break;
      case 1:
        // 2do impacto: velocidad verde (130.0)
        _speed = 130.0 * variation;
        break;
      case 0:
        // 3er impacto: velocidad roja (180.0) - será destruido
        _speed = 180.0 * variation;
        break;
    }
  }

  void explodeAndReturn() {
    if (!_active) return;
    _active = false;
    if (_pool != null) {
      _pool.release(this);
    } else {
      removeFromParent();
    }
  }

  void _onEscaped() {
    if (!_active) return;
    _active = false;
    onEscaped?.call(this);
    if (_pool != null) {
      _pool.release(this);
    } else {
      removeFromParent();
    }
  }

  void applySlowMultiplier(double multiplier) {
    _speed *= multiplier;
  }
  
  @override
  bool containsLocalPoint(Vector2 point) {
    if (!_active || _tapped) return false;
    return super.containsLocalPoint(point);
  }
}
