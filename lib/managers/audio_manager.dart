// lib/managers/audio_manager.dart
// Gestor de audio: música de fondo y efectos de sonido

import 'dart:async';
import 'dart:math' as math;
import 'package:flame_audio/flame_audio.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Gestiona toda la reproducción de audio del juego.
/// Maneja música de fondo, efectos de sonido por tipo de globo y vibración con un control de volumen maestro.
class AudioManager {
  double _masterVolume = 0.6; // Valor inicial

  // -- Playlist --
  final List<String> _playlist = [
    'bgm1.mp3',
    'bgm2.mp3',
    'bgm3.mp3',
    'bgm4.mp3',
    'bgm5.mp3',
    'bgm6.mp3',
    'bgm7.mp3',
    'bgm8.mp3',
  ];
  int _currentSongIndex = 0;
  AudioPlayer? _bgmPlayer;
  StreamSubscription? _playerCompleteSubscription;
  final Map<String, AudioPool> _sfxPools = {};
  bool _isStartingBgm = false;

  double get masterVolume => _masterVolume;

  /// Precarga todos los assets de audio para evitar latencia en el juego
  Future<void> initialize() async {
    try {
      await FlameAudio.audioCache.loadAll([
        'bgm1.mp3',
        'bgm2.mp3',
        'bgm3.mp3',
        'bgm4.mp3',
        'bgm5.mp3',
        'bgm6.mp3',
        'bgm7.mp3',
        'bgm8.mp3',
        'pop_bubble.mp3',
        'ice.mp3',
        'pop_black.mp3',
        'bird_hit.mp3',
        'level_up.mp3',
      ]);

      _sfxPools['pop_bubble.mp3'] = await FlameAudio.createPool('pop_bubble.mp3', minPlayers: 15, maxPlayers: 30);
      _sfxPools['ice.mp3'] = await FlameAudio.createPool('ice.mp3', minPlayers: 3, maxPlayers: 5);
      _sfxPools['pop_black.mp3'] = await FlameAudio.createPool('pop_black.mp3', minPlayers: 2, maxPlayers: 4);
      _sfxPools['bird_hit.mp3'] = await FlameAudio.createPool('bird_hit.mp3', minPlayers: 2, maxPlayers: 3);
      _sfxPools['level_up.mp3'] = await FlameAudio.createPool('level_up.mp3', minPlayers: 1, maxPlayers: 2);
    } catch (e) {
      debugPrint('[AudioManager] Error loading audio: $e');
    }
  }

  bool _shouldPlayBgm = false;

  /// Reproduce la música de fondo actual
  Future<void> playBgm() async {
    _shouldPlayBgm = true;
    if (_masterVolume <= 0) return;
    try {
      if (_bgmPlayer == null) {
        _bgmPlayer = AudioPlayer();
        _playerCompleteSubscription = _bgmPlayer!.onPlayerComplete.listen((_) {
          _playNextSong();
        });
      }
      final effectiveVolume = _masterVolume * _masterVolume;
      await _bgmPlayer!.setVolume(effectiveVolume);
      
      // Chequeo de seguridad antes de reproducir
      if (!_shouldPlayBgm) return;
      
      await _bgmPlayer!.play(AssetSource('audio/${_playlist[_currentSongIndex]}'));
      
      // Chequeo de seguridad por si stopBgm se llamó mientras cargaba el asset
      if (!_shouldPlayBgm) {
        await _bgmPlayer!.stop();
      }
    } catch (e) {
      debugPrint('[AudioManager] BGM error: $e');
    }
  }

  final _random = math.Random();

  void _playNextSong() {
    if (_playlist.length <= 1) return;
    int nextIndex = _currentSongIndex;
    while (nextIndex == _currentSongIndex) {
      nextIndex = _random.nextInt(_playlist.length);
    }
    _currentSongIndex = nextIndex;
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
    if (_masterVolume <= 0) return;
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
    _shouldPlayBgm = false;
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

  /// Ajusta el volumen general del juego (0.0 - 1.0)
  Future<void> setMasterVolume(double volume) async {
    _masterVolume = volume.clamp(0.0, 1.0);
    final effectiveVolume = _masterVolume * _masterVolume;
    
    if (_masterVolume > 0) {
      if (_bgmPlayer?.state == PlayerState.playing || _isStartingBgm) {
        await _bgmPlayer?.setVolume(effectiveVolume);
      } else {
        _isStartingBgm = true;
        await playBgm();
        _isStartingBgm = false;
      }
    } else {
      await stopBgm();
    }
  }

  /// Libera los recursos de audio
  Future<void> dispose() async {
    try {
      await _playerCompleteSubscription?.cancel();
      await _bgmPlayer?.dispose();
      for (final pool in _sfxPools.values) {
        pool.dispose();
      }
      FlameAudio.audioCache.clearAll();
    } catch (e) {
      debugPrint('[AudioManager] Dispose error: $e');
    }
  }

  // -- Privado --

  Future<void> _playSfx(String filename) async {
    if (_masterVolume <= 0) return;
    try {
      // Usamos volumen exponencial/logarítmico para mejor percepción
      final effectiveVolume = _masterVolume * _masterVolume;
      if (_sfxPools.containsKey(filename)) {
        await _sfxPools[filename]!.start(volume: effectiveVolume);
      } else {
        await FlameAudio.play(filename, volume: effectiveVolume);
      }
    } catch (e) {
      debugPrint('[AudioManager] SFX error ($filename): $e');
    }
  }
}
