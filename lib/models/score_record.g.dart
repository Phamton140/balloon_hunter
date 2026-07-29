// GENERATED CODE - DO NOT MODIFY BY HAND
// lib/models/score_record.g.dart
// Adaptador Hive generado manualmente para ScoreRecord

part of 'score_record.dart';

class ScoreRecordAdapter extends TypeAdapter<ScoreRecord> {
  @override
  final int typeId = 0;

  @override
  ScoreRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScoreRecord(
      score: fields[0] as int,
      level: fields[1] as int,
      date: fields[2] as DateTime,
      balloonsDestroyed: fields[3] as int,
      accuracy: fields[4] as double,
      maxCombo: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ScoreRecord obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.score)
      ..writeByte(1)
      ..write(obj.level)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.balloonsDestroyed)
      ..writeByte(4)
      ..write(obj.accuracy)
      ..writeByte(5)
      ..write(obj.maxCombo);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScoreRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
