// lib/managers/audio_manager.dart
// Gestor de audio: música de fondo y efectos de sonido

import 'dart:async';
import 'package:flame_audio/flame_audio.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Gestiona toda la reproducción de audio del juego.
/// Maneja música de fondo, efectos de sonido por tipo de globo y vibración.
class AudioManager {
  bool _musicEnabled = true;
  bool _sfxEnabled = true;
  double _musicVolume = 0.6;
  double _sfxVolume = 1.0;

  // -- Playlist --
  final List<String> _playlist = ['bgm1.mp3', 'bgm2.mp3', 'bgm3.mp3'];
  int _currentSongIndex = 0;
  AudioPlayer? _bgmPlayer;
  StreamSubscription? _playerCompleteSubscription;

  bool get musicEnabled => _musicEnabled;
  bool get sfxEnabled => _sfxEnabled;
  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;

  /// Precarga todos los assets de audio para evitar latencia en el juego
  Future<void> initialize() async {
    try {
      await FlameAudio.audioCache.loadAll([
        'bgm1.mp3',
        'bgm2.mp3',
        'bgm3.mp3',
        'pop_bubble.mp3',
        'ice.mp3',
        'pop_black.mp3',
        'bird_hit.mp3',
        'level_up.mp3',
      ]);
    } catch (e) {
      debugPrint('[AudioManager] Error loading audio: $e');
    }
  }

  /// Reproduce la música de fondo actual
  Future<void> playBgm() async {
    if (!_musicEnabled) return;
    try {
      if (_bgmPlayer == null) {
        _bgmPlayer = AudioPlayer();
        _playerCompleteSubscription = _bgmPlayer!.onPlayerComplete.listen((_) {
          _playNextSong();
        });
      }
      await _bgmPlayer!.setVolume(_musicVolume);
      // FlameAudio cachea en la ruta de assets/audio. Audioplayers usa AssetSource
      await _bgmPlayer!.play(AssetSource('audio/${_playlist[_currentSongIndex]}'));
    } catch (e) {
      debugPrint('[AudioManager] BGM error: $e');
    }
  }

  void _playNextSong() {
    _currentSongIndex = (_currentSongIndex + 1) % _playlist.length;
    playBgm();
  }

  /// Pausa la música de fondo
  Future<void> pauseBgm() async {
    try {
      await _bgmPlayer?.pause();
    } catch (e) {
      debugPrint('[AudioManager] Pause BGM error: $e');
    }
  }

  /// Reanuda la música de fondo
  Future<void> resumeBgm() async {
    if (!_musicEnabled) return;
    try {
      if (_bgmPlayer?.state == PlayerState.paused) {
        await _bgmPlayer?.resume();
      } else {
        await playBgm();
      }
    } catch (e) {
      debugPrint('[AudioManager] Resume BGM error: $e');
    }
  }

  /// Detiene la música de fondo
  Future<void> stopBgm() async {
    try {
      await _bgmPlayer?.stop();
    } catch (e) {
      debugPrint('[AudioManager] Stop BGM error: $e');
    }
  }

  /// Sonido al explotar un globo amarillo
  Future<void> playPopYellow() async => _playSfx('pop_bubble.mp3');

  /// Sonido al explotar un globo verde
  Future<void> playPopGreen() async => _playSfx('pop_bubble.mp3');

  /// Sonido al explotar un globo rojo
  Future<void> playPopRed() async => _playSfx('pop_bubble.mp3');

  /// Sonido al activar el globo azul (efecto hielo)
  Future<void> playPopBlue() async => _playSfx('ice.mp3');

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
      await _bgmPlayer?.setVolume(_musicVolume);
    }
  }

  /// Libera los recursos de audio
  Future<void> dispose() async {
    try {
      await _playerCompleteSubscription?.cancel();
      await _bgmPlayer?.dispose();
      FlameAudio.audioCache.clearAll();
    } catch (e) {
      debugPrint('[AudioManager] Dispose error: $e');
    }
  }

  // -- Privado --

  Future<void> _playSfx(String filename) async {
    if (!_sfxEnabled) return;
    try {
      await FlameAudio.play(filename, volume: _sfxVolume);
    } catch (e) {
      debugPrint('[AudioManager] SFX error ($filename): $e');
    }
  }
}
