// lib/managers/save_manager.dart
// Gestiona el guardado persistente del progreso del jugador

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SaveManager {
  static const String _boxName = 'balloon_hunter_save';
  Box? _box;

  Future<void> initialize() async {
    try {
      _box = await Hive.openBox(_boxName);
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

  int get savedLevel => _box?.get('level', defaultValue: 1) as int;
  int get savedScore => _box?.get('score', defaultValue: 0) as int;

  Future<void> saveGame({required int level, required int score}) async {
    if (_box == null) return;
    try {
      await _box!.put('level', level);
      await _box!.put('score', score);
      debugPrint('[SaveManager] Partida guardada -> Nivel: $level, Score: $score');
    } catch (e) {
      debugPrint('[SaveManager] Error saving game: $e');
    }
  }

  Future<void> clearSave() async {
    if (_box == null) return;
    try {
      await _box!.clear();
      debugPrint('[SaveManager] Partida guardada eliminada');
    } catch (e) {
      debugPrint('[SaveManager] Error clearing save: $e');
    }
  }
}
