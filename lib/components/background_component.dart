// lib/components/background_component.dart
// Fondo animado del juego con cambio dinámico basado en tiempo real y días

import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

enum TimeOfDayCategory { morning, afternoon, night }

/// Fondo del juego con imagen de cielo que cambia dinámicamente según la hora local
/// y varía el tema paisajístico dependiendo del día del año.
class BackgroundComponent extends PositionComponent with HasGameReference {
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
  
  // Flag de debug
  bool _isDebugOverride = false;
  bool _isDebugAutoCycle = false;
  double _debugAutoCycleTimer = 0.0;

  @override
  Future<void> onLoad() async {
    size = game.size;
    priority = -10; // Siempre al fondo

    try {
      // Tema 1: Naturaleza estándar
      _themeSprites[0] = [
        await Sprite.load('bg_morning.png'),
        await Sprite.load('bg_afternoon.png'),
        await Sprite.load('bg_night.png'),
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

  /// Calcula un índice (0, 1 o 2) dependiendo del día del año.
  int _getThemeForToday() {
    final now = DateTime.now();
    final dayOfYear = int.parse(now.difference(DateTime(now.year, 1, 1, 0, 0)).inDays.toString());
    return dayOfYear % 3;
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
  
  /// Cicla manualmente el fondo (para modo de prueba de usuario).
  void debugCycleTheme() {
    if (!_spritesLoaded) return;
    
    _isDebugOverride = true;
    _previousCategory = _currentCategory;
    _previousThemeIndex = _currentThemeIndex;
    _fadeTimer = 0.0;
    
    // Ciclar horario (Mañana -> Tarde -> Noche)
    if (_currentCategory == TimeOfDayCategory.morning) {
      _currentCategory = TimeOfDayCategory.afternoon;
    } else if (_currentCategory == TimeOfDayCategory.afternoon) {
      _currentCategory = TimeOfDayCategory.night;
    } else {
      _currentCategory = TimeOfDayCategory.morning;
      // Si completó el ciclo del día, cambiar al siguiente tema
      _currentThemeIndex = (_currentThemeIndex + 1) % 3;
    }
  }

  /// Activa/desactiva la galería de pruebas automáticas
  void toggleDebugAutoCycle() {
    _isDebugAutoCycle = !_isDebugAutoCycle;
    if (_isDebugAutoCycle) {
      _debugAutoCycleTimer = 0.0;
      debugCycleTheme(); // Hace el primer cambio inmediatamente
    }
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

    if (_isDebugAutoCycle) {
      _debugAutoCycleTimer += dt;
      if (_debugAutoCycleTimer >= 5.0) {
        _debugAutoCycleTimer = 0.0;
        debugCycleTheme();
      }
    } else if (!_isDebugOverride) {
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
