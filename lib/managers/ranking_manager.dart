// lib/managers/ranking_manager.dart
// Gestión de puntuaciones y ranking con Hive

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/score_record.dart';
import '../utils/constants.dart';

/// Gestiona la persistencia y lectura del ranking de puntuaciones.
/// Guarda únicamente el Top 3 por puntuación descendente.
class RankingManager {
  Box<ScoreRecord>? _box;

  /// Inicializa Hive y abre la caja de puntuaciones
  Future<void> initialize() async {
    try {
      await Hive.initFlutter();
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(ScoreRecordAdapter());
      }
      _box = await Hive.openBox<ScoreRecord>(GameConstants.rankingBoxName);
    } catch (e) {
      debugPrint('[RankingManager] Hive init error: $e');
    }
  }

  /// Retorna el Top 3 de puntuaciones ordenado de mayor a menor
  List<ScoreRecord> getTopScores() {
    if (_box == null) return [];
    final records = _box!.values.toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return records.take(GameConstants.rankingTopSize).toList();
  }

  /// Retorna la mejor puntuación, o 0 si no hay registros
  int getBestScore() {
    final top = getTopScores();
    return top.isEmpty ? 0 : top.first.score;
  }

  /// Agrega un nuevo registro y mantiene solo el Top 3.
  /// Retorna true si el registro entró en el ranking.
  Future<bool> addRecord(ScoreRecord record) async {
    if (_box == null) return false;
    try {
      await _box!.add(record);
      await _trimToTopN();
      return true;
    } catch (e) {
      debugPrint('[RankingManager] Error adding record: $e');
      return false;
    }
  }

  /// Limpia todos los registros (para testing)
  Future<void> clearAll() async {
    await _box?.clear();
  }

  Future<void> _trimToTopN() async {
    if (_box == null) return;
    final all = _box!.values.toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    if (all.length <= GameConstants.rankingTopSize) return;
    // Borrar los registros más bajos
    final toDelete = all.skip(GameConstants.rankingTopSize).toList();
    for (final record in toDelete) {
      await record.delete();
    }
  }
}
