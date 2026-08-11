import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class FloatingTextComponent extends PositionComponent {
  final String text;
  final Color color;
  double _lifeTimer = 0.0;
  static const double _lifeSpan = 1.5; // Segundos antes de desaparecer
  late final TextPaint _textPaint;

  FloatingTextComponent({
    required this.text,
    required Vector2 position,
    this.color = Colors.yellowAccent,
  }) : super(position: position) {
    anchor = Anchor.center;
    _textPaint = TextPaint(
      style: TextStyle(
        fontSize: 32,
        color: color,
        fontWeight: FontWeight.bold,
        shadows: const [
          Shadow(
            color: Colors.black54,
            offset: Offset(2, 2),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _lifeTimer += dt;
    
    // Sube lentamente
    position.y -= 50 * dt;

    if (_lifeTimer >= _lifeSpan) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    // Fade out en el último 0.5s
    double opacity = 1.0;
    if (_lifeTimer > _lifeSpan - 0.5) {
      opacity = ((_lifeSpan - _lifeTimer) / 0.5).clamp(0.0, 1.0);
    }
    
    final paint = _textPaint.copyWith(
      (style) => style.copyWith(color: color.withOpacity(opacity)),
    );
    
    paint.render(
      canvas,
      text,
      Vector2.zero(),
      anchor: Anchor.center,
    );
  }
}
