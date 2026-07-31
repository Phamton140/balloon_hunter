// lib/screens/pause_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../managers/game_manager.dart';
import '../utils/palette.dart';

class PauseScreen extends StatelessWidget {
  final GameManager gameManager;
  final VoidCallback? onResume;
  final VoidCallback? onMenu;

  const PauseScreen({
    super.key,
    required this.gameManager,
    this.onResume,
    this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black, // Fondo opaco para evitar trampas
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Palette.menuGradientTop.withOpacity(0.95),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '⏸ PAUSADO',
                style: GoogleFonts.fredoka(fontSize: 28, color: Colors.white),
              ).animate().fadeIn().scale(),

              const SizedBox(height: 8),
              Container(height: 1, color: Colors.white12),
              const SizedBox(height: 24),

              // Controles de audio
              ListenableBuilder(
                listenable: gameManager,
                builder: (context, _) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _AudioToggle(
                      icon: gameManager.audioManager.musicEnabled
                          ? Icons.music_note
                          : Icons.music_off,
                      label: 'Música',
                      active: gameManager.audioManager.musicEnabled,
                      onTap: () async {
                        await gameManager.audioManager.toggleMusic();
                        // ignore: invalid_use_of_protected_member
                        (gameManager as dynamic).notifyListeners?.call();
                      },
                    ),
                  ],
                ),
              ),

              // Control de Volumen de Música
              ListenableBuilder(
                listenable: gameManager,
                builder: (context, _) {
                  if (!gameManager.audioManager.musicEnabled) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        'Volumen',
                        style: GoogleFonts.fredoka(fontSize: 14, color: Colors.white70),
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Palette.balloonBlue,
                          inactiveTrackColor: Colors.white24,
                          thumbColor: Palette.balloonBlue,
                          overlayColor: Palette.balloonBlue.withOpacity(0.2),
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: gameManager.audioManager.musicVolume,
                          min: 0.0,
                          max: 1.0,
                          onChanged: (value) async {
                            await gameManager.audioManager.setMusicVolume(value);
                            // ignore: invalid_use_of_protected_member
                            (gameManager as dynamic).notifyListeners?.call();
                          },
                        ),
                      ),
                    ],
                  ).animate().fadeIn();
                },
              ),

              const SizedBox(height: 24),

              // Reanudar
              _PauseButton(
                label: '▶ REANUDAR',
                color: const Color(0xFF43E97B),
                onTap: () => onResume?.call(),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 12),

              // Menú
              _PauseButton(
                label: '🏠 MENÚ',
                color: Palette.buttonSecondary,
                onTap: () => onMenu?.call(),
              ).animate().fadeIn(delay: 200.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _AudioToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _AudioToggle({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: active ? Colors.white24 : Colors.white10,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active ? Colors.white38 : Colors.white12,
              ),
            ),
            child: Icon(icon, color: active ? Colors.white : Colors.white38, size: 26),
          ),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.fredoka(fontSize: 11, color: Colors.white60)),
        ],
      ),
    );
  }
}

class _PauseButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PauseButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Center(
          child: Text(label, style: GoogleFonts.fredoka(fontSize: 18, color: Colors.white)),
        ),
      ),
    );
  }
}
