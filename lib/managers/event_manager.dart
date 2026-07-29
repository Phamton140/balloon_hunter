// lib/managers/event_manager.dart
// Sistema de eventos especiales - dispatcher central

import 'package:flutter/foundation.dart';
import '../models/game_event.dart';

/// Gestiona el despacho de eventos especiales durante la partida.
/// Implementa un patrón observer/handler simple y extensible.
/// Los componentes se suscriben a tipos de evento y reciben notificaciones.
class EventManager {
  final Map<GameEventType, List<void Function(GameEvent)>> _handlers = {};

  /// Registra un handler para un tipo de evento específico
  void register(GameEventType type, void Function(GameEvent) handler) {
    _handlers.putIfAbsent(type, () => []).add(handler);
    debugPrint('[EventManager] Handler registered for $type');
  }

  /// Elimina todos los handlers de un tipo
  void unregister(GameEventType type) {
    _handlers.remove(type);
  }

  /// Elimina un handler específico de un tipo
  void unregisterHandler(GameEventType type, void Function(GameEvent) handler) {
    _handlers[type]?.remove(handler);
  }

  /// Dispara un evento a todos sus handlers registrados
  void trigger(GameEventType type, {Map<String, dynamic> params = const {}, double duration = 0.0}) {
    final event = GameEvent(
      type: type,
      duration: duration,
      params: params,
      timestamp: DateTime.now(),
    );
    final handlers = _handlers[type];
    if (handlers == null || handlers.isEmpty) {
      debugPrint('[EventManager] No handlers for $type');
      return;
    }
    for (final handler in List.from(handlers)) {
      try {
        handler(event);
      } catch (e) {
        debugPrint('[EventManager] Handler error for $type: $e');
      }
    }
    debugPrint('[EventManager] Triggered $type with ${handlers.length} handlers');
  }

  /// Limpia todos los handlers (usar al salir del juego)
  void clearAll() {
    _handlers.clear();
  }
}
