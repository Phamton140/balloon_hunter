// lib/managers/audio_manager.dart
// Gestor de audio: música de fondo y efectos de sonido

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

/// Gestiona toda la reproducción de audio del juego.
/// Maneja música de fondo, efectos de sonido por tipo de globo y vibración.
class AudioManager {
  bool _musicEnabled = true;
  bool _sfxEnabled = true;
  double _musicVolume = 0.6;
  double _sfxVolume = 1.0;

  bool get musicEnabled => _musicEnabled;
  bool get sfxEnabled => _sfxEnabled;
  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;

  /// Precarga todos los assets de audio para evitar latencia en el juego
  Future<void> initialize() async {
    try {
      await FlameAudio.audioCache.loadAll([
        'bgm.mp3',
        'pop_yellow.mp3',
        'pop_green.mp3',
        'pop_red.mp3',
        'pop_blue.mp3',
        'pop_black.mp3',
        'bird_hit.mp3',
        'level_up.mp3',
      ]);
    } catch (e) {
      debugPrint('[AudioManager] Error loading audio: $e');
    }
  }

  /// Reproduce la música de fondo en bucle
  Future<void> playBgm() async {
    if (!_musicEnabled) return;
    try {
      await FlameAudio.bgm.play('bgm.mp3', volume: _musicVolume);
    } catch (e) {
      debugPrint('[AudioManager] BGM error: $e');
    }
  }

  /// Pausa la música de fondo
  Future<void> pauseBgm() async {
    try {
      await FlameAudio.bgm.pause();
    } catch (e) {
      debugPrint('[AudioManager] Pause BGM error: $e');
    }
  }

  /// Reanuda la música de fondo
  Future<void> resumeBgm() async {
    if (!_musicEnabled) return;
    try {
      await FlameAudio.bgm.resume();
    } catch (e) {
      debugPrint('[AudioManager] Resume BGM error: $e');
    }
  }

  /// Detiene la música de fondo
  Future<void> stopBgm() async {
    try {
      await FlameAudio.bgm.stop();
    } catch (e) {
      debugPrint('[AudioManager] Stop BGM error: $e');
    }
  }

  /// Sonido al explotar un globo amarillo
  Future<void> playPopYellow() async => _playSfx('pop_yellow.mp3');

  /// Sonido al explotar un globo verde
  Future<void> playPopGreen() async => _playSfx('pop_green.mp3');

  /// Sonido al explotar un globo rojo
  Future<void> playPopRed() async => _playSfx('pop_red.mp3');

  /// Sonido al activar el globo azul (efecto hielo)
  Future<void> playPopBlue() async => _playSfx('pop_blue.mp3');

  /// Sonido al activar el globo negro (explosión masiva)
  Future<void> playPopBlack() async => _playSfx('pop_black.mp3');

  /// Sonido de Game Over por disparar un ave
  Future<void> playBirdHit() async => _playSfx('bird_hit.mp3');

  /// Sonido de subida de nivel
  Future<void> playLevelUp() async => _playSfx('level_up.mp3');

  /// Activa/desactiva la música
  Future<void> toggleMusic() async {
    _musicEnabled = !_musicEnabled;
    if (_musicEnabled) {
      await playBgm();
    } else {
      await stopBgm();
    }
  }

  /// Activa/desactiva los efectos de sonido
  void toggleSfx() {
    _sfxEnabled = !_sfxEnabled;
  }

  /// Ajusta el volumen de la música (0.0 - 1.0)
  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    if (_musicEnabled) {
      FlameAudio.bgm.audioPlayer.setVolume(_musicVolume);
    }
  }

  /// Libera los recursos de audio
  Future<void> dispose() async {
    try {
      await FlameAudio.bgm.stop();
      FlameAudio.audioCache.clearAll();
    } catch (e) {
      debugPrint('[AudioManager] Dispose error: $e');
    }
  }

  // -- Privado --

  Future<void> _playSfx(String filename) async {
    if (!_sfxEnabled) return;
    try {
      // await FlameAudio.play(filename, volume: _sfxVolume);
      // Deshabilitado temporalmente para evitar lag/stutter si los archivos no existen
    } catch (e) {
      debugPrint('[AudioManager] SFX error ($filename): $e');
    }
  }
}
