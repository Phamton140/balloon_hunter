// lib/utils/sound_pool.dart
// Pool de efectos de sonido para reproducción sin latencia

import 'package:flutter/foundation.dart';
import '../managers/audio_manager.dart';
import '../models/balloon_type.dart';

/// Wrapper de conveniencia para reproducir sonidos de globos
/// según el tipo sin necesidad de un switch/case en cada lugar.
class SoundPool {
  final AudioManager _audioManager;

  SoundPool(this._audioManager);

  /// Reproduce el sonido correspondiente al tipo de globo
  Future<void> playForBalloonType(BalloonType type) async {
    try {
      switch (type) {
        case BalloonType.yellow:
          await _audioManager.playPopYellow();
          break;
        case BalloonType.green:
          await _audioManager.playPopGreen();
          break;
        case BalloonType.red:
          await _audioManager.playPopRed();
          break;
        case BalloonType.blue:
          await _audioManager.playPopBlue();
          break;
        case BalloonType.black:
          // El globo negro tiene su propia lógica en GameManager
          break;
        default:
          await _audioManager.playPopYellow();
          break;
      }
    } catch (e) {
      debugPrint('[SoundPool] Error playing sound for $type: $e');
    }
  }
}
