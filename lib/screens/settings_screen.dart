// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../managers/game_manager.dart';
import '../managers/save_manager.dart';
import '../utils/palette.dart';
import '../utils/countries.dart';

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
  double _previousVolume = 0.6;

  @override
  void dispose() {
    widget.gameManager.audioManager.stopBgm();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audio = widget.gameManager.audioManager;
    final theme = widget.gameManager.saveManager.currentTheme;

    return Container(
      decoration: const BoxDecoration(
        gradient: Palette.menuGradient,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      widget.gameManager.audioManager.stopBgm();
                      widget.onBack?.call();
                    },
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
                  
                  _ProfileCard(gameManager: widget.gameManager),

                  const SizedBox(height: 16),

                  _SettingCard(
                    icon: audio.masterVolume > 0 ? Icons.volume_up : Icons.volume_off,
                    title: 'Volumen General',
                    subtitle: '${(audio.masterVolume * 100).round()}%',
                    trailing: const SizedBox.shrink(),
                    onIconTap: () async {
                      if (audio.masterVolume > 0) {
                        _previousVolume = audio.masterVolume;
                        await audio.setMasterVolume(0.0);
                      } else {
                        await audio.setMasterVolume(_previousVolume > 0 ? _previousVolume : 0.6);
                      }
                      setState(() {});
                    },
                    bottom: Slider(
                      value: audio.masterVolume,
                      min: 0.0,
                      max: 1.0,
                      activeColor: const Color(0xFF43E97B),
                      inactiveColor: Colors.white24,
                      onChanged: (v) async {
                        await audio.setMasterVolume(v);
                        if (v > 0) _previousVolume = v;
                        setState(() {});
                      },
                    ),
                  ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2),

                  const SizedBox(height: 16),

                  _SettingCard(
                    icon: Icons.delete_forever,
                    title: 'Restablecer Progreso (Modo Pruebas)',
                    subtitle: 'Borra puntuaciones y nivel, pero mantiene tu usuario',
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: const Color(0xFF2C2C2C),
                            title: Text('¿Restablecer progreso?', style: GoogleFonts.fredoka(color: Colors.white)),
                            content: const Text(
                              'Esto borrará tu récord personal, nivel alcanzado y tiempo de juego de forma irreversible, tanto localmente como en la nube.\n\nTu usuario, código de amigo y amigos seguirán intactos.',
                              style: TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx), 
                                child: const Text('Cancelar', style: TextStyle(color: Colors.white54))
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  await widget.gameManager.wipeGameData();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Progreso restablecido.'))
                                    );
                                  }
                                },
                                child: Text('Confirmar', style: GoogleFonts.fredoka(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Text('BORRAR', style: GoogleFonts.fredoka(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2),

                  const SizedBox(height: 16),
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
  final VoidCallback? onIconTap;

  const _SettingCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.bottom,
    this.onIconTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onIconTap,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white70, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.fredoka(fontSize: 16, color: Colors.white)),
                    Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.white70)),
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

class _ProfileCard extends StatefulWidget {
  final GameManager gameManager;
  
  const _ProfileCard({required this.gameManager});

  @override
  State<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<_ProfileCard> {
  String _formatTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  void _showAddFriendDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: Text('Añadir Amigo por Código', style: GoogleFonts.fredoka(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Ej. BHT-X7K9',
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF43E97B)),
            onPressed: () async {
              final success = await widget.gameManager.friendsManager.addFriendByCode(controller.text);
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? '¡Amigo añadido con éxito!' : 'Código inválido o ya lo sigues')));
              }
            },
            child: Text('Añadir', style: GoogleFonts.fredoka(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  String _getFlag(String countryCode) {
    if (countryCode.length != 2) return '🏳️';
    int firstLetter = countryCode.codeUnitAt(0) - 0x41 + 0x1F1E6;
    int secondLetter = countryCode.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCode(firstLetter) + String.fromCharCode(secondLetter);
  }

  @override
  Widget build(BuildContext context) {
    final auth = widget.gameManager.authManager;
    final save = widget.gameManager.saveManager;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.white12,
                  shape: BoxShape.circle,
                ),
                child: Text(_getFlag(auth.playerCountryCode), style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(auth.playerName, style: GoogleFonts.fredoka(fontSize: 18, color: Colors.white)),
                    Text('Tiempo jugado: ${_formatTime(save.totalPlayTimeSeconds)}', style: const TextStyle(fontSize: 13, color: Colors.white70)),
                    Text('Código: ${widget.gameManager.friendsManager.myFriendCode}', style: const TextStyle(fontSize: 13, color: Color(0xFF43E97B))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
