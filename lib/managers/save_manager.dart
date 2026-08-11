// lib/managers/save_manager.dart
// Gestiona el guardado persistente del progreso del jugador

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum AppTheme { wood, modern }

class SaveManager {
  static const String _boxName = 'balloon_hunter_save';
  Box? _box;

  Future<void> initialize() async {
    try {
      _box = await Hive.openBox(_boxName);

      // Auto-reparación (Self-healing): 
      // Si por culpa del bug anterior el maxLevel se borró, pero el usuario 
      // todavía tiene una partida guardada en un nivel avanzado, restauramos el maxLevel.
      final currentLevel = _box!.get('level', defaultValue: 0) as int;
      final currentMax = _box!.get('maxLevel', defaultValue: 0) as int;
      if (currentLevel > currentMax) {
        await _box!.put('maxLevel', currentLevel);
        debugPrint('[SaveManager] Auto-reparado maxLevel a $currentLevel');
      }
    } catch (e) {
      debugPrint('[SaveManager] Error initializing box: $e');
    }
  }

  bool get hasSavedGame {
    if (_box == null) return false;
    final level = _box!.get('level', defaultValue: 1) as int;
    final score = _box!.get('score', defaultValue: 0) as int;
    return level > 1 || score > 0;
  }

  int get savedLevel => _box?.get('level', defaultValue: 1) ?? 1;
  int get savedScore => _box?.get('score', defaultValue: 0) ?? 0;
  
  bool get hasRegistered => _box?.get('hasRegistered', defaultValue: false) ?? false;
  
  AppTheme get currentTheme {
    final themeStr = _box?.get('theme', defaultValue: 'wood') as String;
    return themeStr == 'modern' ? AppTheme.modern : AppTheme.wood;
  }

  Future<void> setHasRegistered(bool value) async {
    await _box?.put('hasRegistered', value);
  }

  Future<void> setTheme(AppTheme theme) async {
    await _box?.put('theme', theme.name);
  }

  /// Nivel máximo histórico alcanzado por el jugador (para desbloqueos)
  int get maxLevelReached => _box?.get('maxLevel', defaultValue: 0) ?? 0;

  Future<void> saveGame({required int level, required int score}) async {
    if (_box == null) return;
    try {
      await _box!.put('level', level);
      await _box!.put('score', score);
      
      // Actualizar el récord de nivel si es mayor
      if (level > maxLevelReached) {
        await _box!.put('maxLevel', level);
      }
      
      debugPrint('[SaveManager] Partida guardada -> Nivel: $level, Score: $score');
    } catch (e) {
      debugPrint('[SaveManager] Error saving game: $e');
    }
  }

  Future<void> clearSave() async {
    if (_box == null) return;
    try {
      await _box!.delete('level');
      await _box!.delete('score');
      debugPrint('[SaveManager] Partida guardada eliminada');
    } catch (e) {
      debugPrint('[SaveManager] Error clearing save: $e');
    }
  }

  /// Guarda el récord personal completo en formato Map
  Future<void> savePersonalRecord(Map<String, dynamic> recordMap) async {
    if (_box == null) return;
    try {
      final currentMaxScore = _box!.get('maxScore', defaultValue: 0) as int;
      final newScore = (recordMap['score'] as num?)?.toInt() ?? 0;
      
      if (newScore > currentMaxScore) {
        await _box!.put('maxScore', newScore);
        // Hive converts String maps to dynamic maps, so we ensure it's saved properly
        await _box!.put('personalRecord', recordMap);
        debugPrint('[SaveManager] Nuevo récord personal guardado localmente: $newScore');
      }
    } catch (e) {
      debugPrint('[SaveManager] Error saving personal record: $e');
    }
  }

  /// Retorna el récord personal guardado localmente
  Map<String, dynamic>? getPersonalRecord() {
    if (_box == null) return null;
    try {
      final record = _box!.get('personalRecord');
      if (record != null) {
        return Map<String, dynamic>.from(record as Map);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  // =========================================================================
  // Perfil del Jugador
  // =========================================================================

  String? get playerName => _box?.get('playerName');
  String? get playerCountryCode => _box?.get('playerCountryCode');
  int get totalPlayTimeSeconds => _box?.get('totalPlayTimeSeconds', defaultValue: 0) ?? 0;

  Future<void> saveProfile({required String name, required String countryCode}) async {
    if (_box == null) return;
    try {
      await _box!.put('playerName', name);
      await _box!.put('playerCountryCode', countryCode);
    } catch (e) {
      debugPrint('[SaveManager] Error saving profile: $e');
    }
  }

  Future<void> addPlayTime(int seconds) async {
    if (_box == null) return;
    try {
      final current = totalPlayTimeSeconds;
      await _box!.put('totalPlayTimeSeconds', current + seconds);
    } catch (e) {
      debugPrint('[SaveManager] Error saving playtime: $e');
    }
  }
}
