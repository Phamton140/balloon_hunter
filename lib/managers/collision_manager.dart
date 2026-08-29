// lib/managers/collision_manager.dart  
// Gestión de lógica de colisión y respuesta a toques

import 'package:flutter/foundation.dart';
import '../models/balloon_type.dart';
import '../components/armored_balloon_component.dart'; // Importar el componente

/// Gestiona la respuesta a los eventos de toque del jugador.
/// Centraliza la lógica de qué ocurre cuando se toca cada tipo de entidad.
class CollisionManager {
  // Callbacks registrados por el juego principal
  void Function(BalloonType type)? onBalloonHit;
  void Function(ArmoredBalloonComponent armored)? onArmoredBalloonHit; // <-- AÑADIDO
  void Function()? onBirdHit;
  void Function(BalloonType type)? onSpecialBalloonHit;
  void Function()? onMiss;

  /// Procesa un toque sobre un globo normal
  void handleBalloonTap(BalloonType type) {
    debugPrint('[CollisionManager] Balloon tapped: $type');
    onBalloonHit?.call(type);
  }

  /// Procesa un toque sobre un globo blindado <-- AÑADIDO
  void handleArmoredBalloonTap(ArmoredBalloonComponent armored) {
    debugPrint('[CollisionManager] Armored balloon tapped (HP restante: ${armored.hp - 1})');
    onArmoredBalloonHit?.call(armored);
  }

  /// Procesa un toque sobre un ave → GAME OVER
  void handleBirdTap() {
    debugPrint('[CollisionManager] Bird tapped! GAME OVER');
    onBirdHit?.call();
  }

  /// Procesa un toque sobre un globo especial (azul o negro)
  void handleSpecialBalloonTap(BalloonType type) {
    debugPrint('[CollisionManager] Special balloon tapped: $type');
    onSpecialBalloonHit?.call(type);
  }

  /// Procesa un tap en zona vacía (miss)
  void handleMiss() {
    onMiss?.call();
  }

  void reset() {
    onBalloonHit = null;
    onArmoredBalloonHit = null; // <-- AÑADIDO
    onBirdHit = null;
    onSpecialBalloonHit = null;
    onMiss = null;
  }
}