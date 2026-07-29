// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../managers/game_manager.dart';
import '../utils/palette.dart';

class SettingsScreen extends StatefulWidget {
  final GameManager gameManager;
  final VoidCallback? onBack;

  const SettingsScreen({
    super.key,
    required this.gameManager,
    this.onBack,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final audio = widget.gameManager.audioManager;

    return Container(
      decoration: const BoxDecoration(gradient: Palette.menuGradient),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => widget.onBack?.call(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '⚙️ AJUSTES',
                    style: GoogleFonts.fredoka(fontSize: 28, color: Colors.white),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  const SizedBox(height: 12),

                  _SettingCard(
                    icon: Icons.music_note,
                    title: 'Música de fondo',
                    subtitle: audio.musicEnabled ? 'Activada' : 'Desactivada',
                    trailing: Switch(
                      value: audio.musicEnabled,
                      activeColor: const Color(0xFF43E97B),
                      onChanged: (_) async {
                        await audio.toggleMusic();
                        setState(() {});
                      },
                    ),
                  ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2),

                  const SizedBox(height: 12),

                  _SettingCard(
                    icon: Icons.volume_up,
                    title: 'Efectos de sonido',
                    subtitle: audio.sfxEnabled ? 'Activados' : 'Desactivados',
                    trailing: Switch(
                      value: audio.sfxEnabled,
                      activeColor: const Color(0xFF43E97B),
                      onChanged: (_) {
                        audio.toggleSfx();
                        setState(() {});
                      },
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2),

                  const SizedBox(height: 12),

                  _SettingCard(
                    icon: Icons.music_video,
                    title: 'Volumen de música',
                    subtitle: '${(audio.musicVolume * 100).round()}%',
                    trailing: const SizedBox.shrink(),
                    bottom: Slider(
                      value: audio.musicVolume,
                      min: 0.0,
                      max: 1.0,
                      activeColor: const Color(0xFF43E97B),
                      inactiveColor: Colors.white24,
                      onChanged: (v) async {
                        await audio.setMusicVolume(v);
                        setState(() {});
                      },
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2),

                  const SizedBox(height: 24),

                  // Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '🎈 Balloon Hunter',
                          style: GoogleFonts.fredoka(fontSize: 18, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Versión 1.0.0\nFlutter + Flame Engine',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.fredoka(fontSize: 13, color: Colors.white38),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final Widget? bottom;

  const _SettingCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white70, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.fredoka(fontSize: 15, color: Colors.white)),
                    Text(subtitle, style: GoogleFonts.fredoka(fontSize: 12, color: Colors.white38)),
                  ],
                ),
              ),
              trailing,
            ],
          ),
          if (bottom != null) bottom!,
        ],
      ),
    );
  }
}
