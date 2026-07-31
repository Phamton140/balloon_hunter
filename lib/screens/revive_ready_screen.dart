// lib/screens/revive_ready_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../managers/game_manager.dart';
import '../utils/palette.dart';

class ReviveReadyScreen extends StatelessWidget {
  final GameManager gameManager;
  final VoidCallback onContinue;

  const ReviveReadyScreen({
    super.key,
    required this.gameManager,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '¡Estás de vuelta!',
              style: GoogleFonts.fredoka(
                fontSize: 40,
                color: Colors.white,
                shadows: [
                  const Shadow(
                    color: Palette.balloonGreen,
                    blurRadius: 15,
                  )
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2),
            const SizedBox(height: 20),
            Text(
              'Toca continuar cuando estés listo',
              style: GoogleFonts.fredoka(fontSize: 18, color: Colors.white70),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: onContinue,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Palette.balloonGreen, Color(0xFF00B09B)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Palette.balloonGreen.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Text(
                  'CONTINUAR',
                  style: GoogleFonts.fredoka(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.05, 1.05), duration: 800.ms),
            ),
          ],
        ),
      ),
    );
  }
}
