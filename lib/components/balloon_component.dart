// lib/components/balloon_component.dart
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../models/balloon_type.dart';
import '../utils/constants.dart';

/// Representa un globo estándar en el juego.
/// Al ser tocado notifica al juego para procesar el impacto.
/// Compatible con Object Pooling: usa configure() para resetear estado.
class BalloonComponent extends PositionComponent
    with TapCallbacks, HasGameReference {
  // -- Tipo y propiedades --
  BalloonType _type = BalloonType.yellow;
  BalloonType get balloonType => _type;

  // -- Movimiento --
  double _speed = 0.0;
  double _baseX = 0.0;
  
  // -- Animación (viento) --
  double _oscillationTime = 0.0;
  double _oscillationAmplitude = 0.0;
  double _oscillationFreq = 0.0;
  double _oscillationPhase = 0.0;

  // -- Pool (puede ser null si no se usa pool) --
  dynamic _pool;

  // -- Estado --
  bool _active = false;
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
    super.update(dt);

    _oscillationTime += dt;

    // Oscilación horizontal (simulación de viento)
    final dx = sin(_oscillationTime * _oscillationFreq + _oscillationPhase) *
        _oscillationAmplitude;
    position.x = _baseX + dx;

    // Ascenso vertical
    position.y -= _speed * dt;

    // Verificar si escapó por la parte superior
    if (position.y < -GameConstants.balloonHeight) {
      _onEscaped();
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_active) return;

    // Dibujar globo programático
    canvas.save();
    // Flame PositionComponent renderiza con (0,0) en la esquina superior izquierda del size.
    // Trasladamos al centro para dibujar desde el centro (como antes con Offset.zero)
    canvas.translate(size.x / 2, size.y / 2);
    
    final paint = Paint()..color = _type.color;
    final glowPaint = Paint()
      ..color = _type.glowColor.withValues(alpha: 0.4)
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
    final knotPaint = Paint()..color = _type.color.withValues(alpha: 0.8);
    final knotY = GameConstants.balloonHeight * 0.42;
    canvas.drawCircle(
      Offset(0, knotY),
      5,
      knotPaint,
    );

    // Hilo del globo
    final stringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final stringPath = Path();
    stringPath.moveTo(0, knotY + 2);
    // Hilo ondulante
    stringPath.quadraticBezierTo(
      sin(_oscillationTime * 3) * 12, knotY + 15,
      -sin(_oscillationTime * 3) * 8, knotY + 30
    );
    canvas.drawPath(stringPath, stringPaint);

    canvas.restore();
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

  /// Actualiza la velocidad en tiempo real (para slow motion)
  void applySlowMultiplier(double multiplier) {
    _speed *= multiplier;
  }
}
