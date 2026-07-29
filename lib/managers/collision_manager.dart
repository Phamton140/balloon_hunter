// lib/managers/collision_manager.dart  
// Gestión de lógica de colisión y respuesta a toques

import 'package:flutter/foundation.dart';
import '../models/balloon_type.dart';

/// Gestiona la respuesta a los eventos de toque del jugador.
/// Centraliza la lógica de qué ocurre cuando se toca cada tipo de entidad.
class CollisionManager {
  // Callbacks registrados por el juego principal
  void Function(BalloonType type)? onBalloonHit;
  void Function()? onBirdHit;
  void Function(BalloonType type)? onSpecialBalloonHit;
  void Function()? onMiss;

  /// Procesa un toque sobre un globo normal
  void handleBalloonTap(BalloonType type) {
    debugPrint('[CollisionManager] Balloon tapped: $type');
    onBalloonHit?.call(type);
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
    onBirdHit = null;
    onSpecialBalloonHit = null;
    onMiss = null;
  }
}
