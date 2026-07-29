// lib/models/game_event.dart
// Sistema de eventos especiales - arquitectura preparada para expansión futura

/// Tipos de eventos especiales que pueden ocurrir durante una partida.
/// Los eventos pueden ser disparados por EnemyDirector y procesados por EventManager.
enum GameEventType {
  /// Ráfaga de viento: aumenta la amplitud de oscilación de los globos temporalmente
  windGust,

  /// Lluvia de globos: spike de spawning durante 5 segundos
  balloonRain,

  /// Enjambre de aves: aumenta la frecuencia de aparición de aves temporalmente
  birdSwarm,

  /// Modo lento activado (por globo azul)
  slowMotionStart,

  /// Modo lento terminado
  slowMotionEnd,

  /// Explosión masiva (globo negro activado)
  blackBalloonExplosion,

  // ============================================================
  // Eventos futuros (no implementados en v1.0):
  // ============================================================
  // bonusRound,       // Ronda bonus sin aves
  // doublePoints,     // Puntos x2 por 10 segundos
  // shieldActive,     // Escudo que absorbe 1 globo escapado
  // thunderStorm,     // Cambia visibilidad de la pantalla
}

/// Modelo de un evento especial con su tipo, duración y parámetros adicionales.
class GameEvent {
  /// Tipo del evento
  final GameEventType type;

  /// Duración del efecto en segundos (0 = instantáneo)
  final double duration;

  /// Parámetros adicionales específicos del evento
  final Map<String, dynamic> params;

  /// Timestamp de creación del evento
  final DateTime timestamp;

  const GameEvent({
    required this.type,
    this.duration = 0.0,
    this.params = const {},
    required this.timestamp,
  });

  /// Crea un evento instantáneo (sin duración)
  factory GameEvent.instant(GameEventType type,
          {Map<String, dynamic> params = const {}}) =>
      GameEvent(
        type: type,
        duration: 0.0,
        params: params,
        timestamp: DateTime.now(),
      );

  /// Crea un evento con duración específica
  factory GameEvent.timed(GameEventType type, double duration,
          {Map<String, dynamic> params = const {}}) =>
      GameEvent(
        type: type,
        duration: duration,
        params: params,
        timestamp: DateTime.now(),
      );

  @override
  String toString() =>
      'GameEvent(type: $type, duration: $duration, params: $params)';
}
