// lib/screens/victory_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../managers/game_manager.dart';
import '../utils/palette.dart';

class VictoryScreen extends StatefulWidget {
  final GameManager gameManager;
  final VoidCallback? onNextLevel;
  final VoidCallback? onMenu;

  const VictoryScreen({
    super.key,
    required this.gameManager,
    this.onNextLevel,
    this.onMenu,
  });

  @override
  State<VictoryScreen> createState() => _VictoryScreenState();
}

class _VictoryScreenState extends State<VictoryScreen> {
  Timer? _timer;
  int _countdown = 2;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        widget.onNextLevel?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stars = widget.gameManager.levelManager.stars;
    final level = widget.gameManager.levelManager.currentLevel;

    return Container(
      color: Colors.black54, // Fondo oscuro semi-transparente para ver el juego de fondo
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '¡NIVEL $level\nCOMPLETADO!',
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  fontSize: 42,
                  color: Colors.white,
                  shadows: [const Shadow(color: Colors.black87, blurRadius: 10, offset: Offset(2, 4))],
                ),
              ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.5, 0.5)),

              const SizedBox(height: 24),

              // Stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final active = i < stars;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      active ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 60,
                      color: active ? Palette.starActive : Palette.starInactive,
                      shadows: active ? [const Shadow(color: Colors.orangeAccent, blurRadius: 12)] : null,
                    )
                        .animate(delay: Duration(milliseconds: 300 + i * 200))
                        .fadeIn()
                        .scale(begin: const Offset(0.0, 0.0), curve: Curves.elasticOut),
                  );
                }),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
