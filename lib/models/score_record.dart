// lib/models/score_record.dart
// Modelo de puntuación para almacenar en Hive

import 'package:hive/hive.dart';

part 'score_record.g.dart';

/// Registro de puntuación extendida almacenado en Hive.
/// Guarda no solo el score, sino estadísticas detalladas de la partida.
@HiveType(typeId: 0)
class ScoreRecord extends HiveObject {
  @HiveField(0)
  final int score;

  @HiveField(1)
  final int level;

  @HiveField(2)
  final DateTime date;

  /// Total de globos destruidos durante la partida
  @HiveField(3)
  final int balloonsDestroyed;

  /// Porcentaje de precisión: globos tocados / (tocados + fallados) * 100
  @HiveField(4)
  final double accuracy;

  /// Mayor combo conseguido durante la partida
  @HiveField(5)
  final int maxCombo;

  ScoreRecord({
    required this.score,
    required this.level,
    required this.date,
    required this.balloonsDestroyed,
    required this.accuracy,
    required this.maxCombo,
  });

  /// Crea un ScoreRecord de ejemplo vacío
  factory ScoreRecord.empty() => ScoreRecord(
        score: 0,
        level: 1,
        date: DateTime.now(),
        balloonsDestroyed: 0,
        accuracy: 0.0,
        maxCombo: 0,
      );

  @override
  String toString() =>
      'ScoreRecord(score: $score, level: $level, accuracy: ${accuracy.toStringAsFixed(1)}%, maxCombo: $maxCombo)';
}
