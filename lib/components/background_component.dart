// lib/components/background_component.dart
// Fondo animado del juego con cambio dinámico basado en tiempo real y días

import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../balloon_hunter_game.dart';

enum TimeOfDayCategory { morning, afternoon, night }

/// Fondo del juego con imagen de cielo que cambia dinámicamente según la hora local
/// y varía el tema paisajístico dependiendo del día del año.
class BackgroundComponent extends PositionComponent with HasGameReference<BalloonHunterGame> {
  final List<List<Sprite>> _themeSprites = [[], [], []];
  
  final List<_Cloud> _clouds = [];
  final Random _random = Random();
  bool _spritesLoaded = false;

  TimeOfDayCategory _currentCategory = TimeOfDayCategory.morning;
  TimeOfDayCategory? _previousCategory;
  
  int _currentThemeIndex = 0;
  int? _previousThemeIndex;

  double _fadeTimer = 0.0;
  static const double _fadeDuration = 3.0; // 3 segundos de transición suave
  double _checkTimeTimer = 0.0;


  @override
  Future<void> onLoad() async {
    size = game.size;
    priority = -10; // Siempre al fondo

    try {
      // Tema 1: Naturaleza estándar
      _themeSprites[0] = [
        await Sprite.load('bg_morning.jpg'),
        await Sprite.load('bg_afternoon.jpg'),
        await Sprite.load('bg_night.jpg'),
      ];

      // Tema 2: Desierto
      _themeSprites[1] = [
        await Sprite.load('bg_morning_2.jpg'),
        await Sprite.load('bg_afternoon_2.jpg'),
        await Sprite.load('bg_night_2.jpg'),
      ];

      // Tema 3: Colinas y Sol
      _themeSprites[2] = [
        await Sprite.load('bg_morning_3.jpg'),
        await Sprite.load('bg_afternoon_3.png'), // Tu imagen original
        await Sprite.load('bg_night_3.jpg'),
      ];

      _spritesLoaded = true;

      // Inicializar categoría y tema actual basado en el tiempo real
      _currentCategory = _getTimeOfDayCategory();
      _currentThemeIndex = _getThemeForToday();
    } catch (e) {
      debugPrint('[BackgroundComponent] Error loading backgrounds: $e');
    }

    // Generar nubes decorativas animadas
    for (int i = 0; i < 5; i++) {
      _clouds.add(_Cloud(
        x: _random.nextDouble() * game.size.x,
        y: _random.nextDouble() * game.size.y * 0.25,
        scale: 0.5 + _random.nextDouble() * 0.6,
        speed: 3.0 + _random.nextDouble() * 5.0,
        opacity: 0.15 + _random.nextDouble() * 0.2,
      ));
    }
  }

  /// Calcula un índice (0, 1 o 2) dependiendo del día del año y de los temas desbloqueados.
  int _getThemeForToday() {
    final now = DateTime.now();
    final dayOfYear = int.parse(now.difference(DateTime(now.year, 1, 1, 0, 0)).inDays.toString());
    
    int maxLevel = game.gameManager.saveManager.maxLevelReached;
    int availableThemes = 1; // Por defecto solo Tema 1
    
    if (maxLevel >= 40) {
      availableThemes = 3; // Tema 1, 2 y 3
    } else if (maxLevel >= 30) {
      availableThemes = 2; // Tema 1 y 2
    }
    
    return dayOfYear % availableThemes;
  }

  TimeOfDayCategory _getTimeOfDayCategory() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) {
      return TimeOfDayCategory.morning;
    } else if (hour >= 12 && hour < 18) {
      return TimeOfDayCategory.afternoon;
    } else {
      return TimeOfDayCategory.night;
    }
  }

  Sprite _getSprite(int themeIndex, TimeOfDayCategory category) {
    return _themeSprites[themeIndex][category.index];
  }
  


  @override
  void update(double dt) {
    super.update(dt);
    
    for (final cloud in _clouds) {
      cloud.x += cloud.speed * dt;
      if (cloud.x > game.size.x + 200) {
        cloud.x = -200;
        cloud.y = _random.nextDouble() * game.size.y * 0.5;
      }
    }

    if (!_spritesLoaded) return;

    if (_previousCategory != null) {
      _fadeTimer += dt;
      if (_fadeTimer >= _fadeDuration) {
        _previousCategory = null;
        _previousThemeIndex = null;
        _fadeTimer = 0.0;
      }
    }

    _checkTimeTimer += dt;
    if (_checkTimeTimer >= 5.0) {
      _checkTimeTimer = 0.0;
      final actualCategory = _getTimeOfDayCategory();
      final actualTheme = _getThemeForToday();
      
      if (actualCategory != _currentCategory || actualTheme != _currentThemeIndex) {
        _previousCategory = _currentCategory;
        _previousThemeIndex = _currentThemeIndex;
        
        _currentCategory = actualCategory;
        _currentThemeIndex = actualTheme;
        _fadeTimer = 0.0;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, game.size.x, game.size.y);

    if (!_spritesLoaded) {
      final paint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF87CEEB), Color(0xFFE0F4FF)],
        ).createShader(rect);
      canvas.drawRect(rect, paint);
    } else {
      if (_previousCategory != null) {
        final oldSprite = _getSprite(_previousThemeIndex ?? _currentThemeIndex, _previousCategory!);
        oldSprite.render(canvas, size: game.size);

        final newSprite = _getSprite(_currentThemeIndex, _currentCategory);
        final progress = (_fadeTimer / _fadeDuration).clamp(0.0, 1.0);
        final paint = Paint()..color = Colors.white.withOpacity(progress);
        newSprite.render(canvas, size: game.size, overridePaint: paint);
      } else {
        final currentSprite = _getSprite(_currentThemeIndex, _currentCategory);
        currentSprite.render(canvas, size: game.size);
      }
    }

    for (final cloud in _clouds) {
      _drawCloud(canvas, cloud);
    }
  }

  void _drawCloud(Canvas canvas, _Cloud cloud) {
    final baseColor = _currentCategory == TimeOfDayCategory.night ? const Color(0xFF546E7A) : Colors.white;
    final paint = Paint()
      ..color = baseColor.withOpacity(cloud.opacity);

    final cx = cloud.x;
    final cy = cloud.y;
    final s = cloud.scale * 60;

    final path = Path();
    
    final baseRect = RRect.fromLTRBR(
      cx - s * 0.8, cy, 
      cx + s * 1.4, cy + s * 0.4, 
      Radius.circular(s * 0.2)
    );
    path.addRRect(baseRect);
    
    path.addOval(Rect.fromCircle(center: Offset(cx - s * 0.3, cy), radius: s * 0.4));
    path.addOval(Rect.fromCircle(center: Offset(cx + s * 0.4, cy - s * 0.2), radius: s * 0.55));
    path.addOval(Rect.fromCircle(center: Offset(cx + s * 0.9, cy + s * 0.1), radius: s * 0.3));

    canvas.drawPath(path, paint);
  }
}

class _Cloud {
  double x;
  double y;
  final double scale;
  final double speed;
  final double opacity;

  _Cloud({
    required this.x,
    required this.y,
    required this.scale,
    required this.speed,
    required this.opacity,
  });
}
