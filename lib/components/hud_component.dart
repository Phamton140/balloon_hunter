// lib/components/hud_component.dart
// HUD del juego renderizado como Flutter overlay

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../managers/game_manager.dart';
import '../utils/palette.dart';
import '../utils/constants.dart';

/// HUD principal del juego. Se muestra como Flutter overlay sobre el GameWidget.
/// Muestra: puntuación, nivel, tiempo, combo, globos escapados, mejor puntuación.
class HudOverlay extends StatelessWidget {
  final GameManager gameManager;
  final VoidCallback onPause;

  const HudOverlay({
    super.key,
    required this.gameManager,
    required this.onPause,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        gameManager,
        gameManager.scoreManager,
        gameManager.levelManager,
        gameManager.timerManager,
      ]),
      builder: (context, _) {
        final score = gameManager.scoreManager.score;
        final level = gameManager.levelManager.currentLevel;
        final escaped = gameManager.levelManager.escapedBalloons;
        final combo = gameManager.scoreManager.combo;
        final bestScore = gameManager.rankingManager.getBestScore();
        final timeStr = gameManager.timerManager.formattedRemaining;
        final remaining = gameManager.timerManager.remaining;
        final isSlowMo = gameManager.slowMotionActive;

        return Column(
          children: [
            // -- Barra superior (Unificada y ultra compacta) --
            _TopBar(
              score: score,
              level: level,
              bestScore: bestScore,
              timeStr: timeStr,
              remaining: remaining,
              isSlowMo: isSlowMo,
              escaped: escaped,
              combo: combo,
              onPause: onPause,
            ),
            const Spacer(),
          ],
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  final int score;
  final int level;
  final int bestScore;
  final String timeStr;
  final double remaining;
  final bool isSlowMo;
  final int escaped;
  final int combo;
  final VoidCallback onPause;

  const _TopBar({
    required this.score,
    required this.level,
    required this.bestScore,
    required this.timeStr,
    required this.remaining,
    required this.isSlowMo,
    required this.escaped,
    required this.combo,
    required this.onPause,
  });

  @override
  Widget build(BuildContext context) {
    final isLowTime = remaining <= 10;
    
    return Container(
      // Padding muy reducido, sin compensar el SafeArea, para que suba hasta el tope real.
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Palette.hudBackground,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(
          bottom: BorderSide(
            color: isSlowMo ? Palette.balloonBlue.withOpacity(0.6) : Colors.white.withOpacity(0.1),
            width: isSlowMo ? 2 : 1,
          )
        ),
        boxShadow: [
          BoxShadow(
            color: isSlowMo ? Palette.balloonBlue.withOpacity(0.3) : Colors.black38,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fila única combinada para ahorrar máximo espacio (o dos muy compactas)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Score & Best
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🏆 $bestScore',
                    style: GoogleFonts.fredoka(
                      fontSize: 10,
                      color: Palette.medalGold,
                    ),
                  ),
                  Text(
                    '⭐ $score',
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      color: Palette.hudText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const Spacer(),

              // Nivel y Escapados (Centro)
              Column(
                children: [
                  Row(
                    children: [
                      if (isSlowMo)
                        Text('❄ ', style: GoogleFonts.fredoka(fontSize: 12, color: Palette.balloonBlue))
                            .animate(onPlay: (c) => c.repeat())
                            .fadeIn(duration: 500.ms)
                            .then()
                            .fadeOut(duration: 500.ms),
                      Text(
                        'NIVEL $level',
                        style: GoogleFonts.fredoka(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Palette.hudAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Escapados compactos debajo del nivel
                  Row(
                    children: List.generate(GameConstants.maxEscapedBalloons, (i) {
                      final isEscaped = i < escaped;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isEscaped ? Palette.hudDanger : Colors.white24,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),

              const Spacer(),

              // Combo, Timer & Pausa (Derecha)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (combo >= GameConstants.comboThreshold1)
                    Text(
                      'x${combo >= GameConstants.comboThreshold3 ? '3.0' : combo >= GameConstants.comboThreshold2 ? '2.0' : '1.5'}',
                      style: GoogleFonts.fredoka(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFFD600),
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.1, 1.1), duration: 600.ms)
                  else
                    const SizedBox(height: 14),

                  Row(
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: GoogleFonts.fredoka(
                          fontSize: isLowTime ? 20 : 18,
                          fontWeight: FontWeight.bold,
                          color: isLowTime ? Palette.hudDanger : Palette.hudText,
                        ),
                        child: Text('⏱ $timeStr'),
                      ).animate(
                        target: isLowTime ? 1 : 0,
                      ).shake(hz: 3, duration: 500.ms),
                      
                      const SizedBox(width: 8),

                      GestureDetector(
                        onTap: onPause,
                        child: const Icon(Icons.pause_circle_filled, color: Colors.white70, size: 24),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
