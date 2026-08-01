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
      // Padding estático y pequeño para pegarlo arriba sin usar MediaQuery
      padding: const EdgeInsets.only(top: 12, bottom: 8, left: 14, right: 14),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Score & Best (Izquierda - Ancho fijo proporcional para evitar saltos)
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🏆 $bestScore',
                        style: GoogleFonts.fredoka(
                          fontSize: 12,
                          color: Palette.medalGold,
                        ),
                      ),
                      Text(
                        '⭐ $score',
                        style: GoogleFonts.fredoka(
                          fontSize: 22,
                          color: Palette.hudText,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Nivel y Escapados (Centro)
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSlowMo)
                            Text('❄ ', style: GoogleFonts.fredoka(fontSize: 14, color: Palette.balloonBlue))
                                .animate(onPlay: (c) => c.repeat())
                                .fadeIn(duration: 500.ms)
                                .then()
                                .fadeOut(duration: 500.ms),
                          Text(
                            'NIVEL $level',
                            style: GoogleFonts.fredoka(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Palette.hudAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Escapados debajo del nivel
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(GameConstants.maxEscapedBalloons, (i) {
                          final isEscaped = i < escaped;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isEscaped ? Palette.hudDanger : Colors.white24,
                              ),
                              child: Center(
                                child: Text(
                                  isEscaped ? '💨' : '',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),

              // Combo, Timer & Pausa (Derecha)
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (combo >= GameConstants.comboThreshold1)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF6B35), Color(0xFFFFD600)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '💥 x${combo >= GameConstants.comboThreshold3 ? '3.0' : combo >= GameConstants.comboThreshold2 ? '2.0' : '1.5'}',
                            style: GoogleFonts.fredoka(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ).animate(onPlay: (c) => c.repeat())
                            // Shimmer en lugar de Scale para evitar mover el layout
                            .shimmer(duration: 1000.ms, color: Colors.white54)
                      else
                        const SizedBox(height: 20), // Espacio vacío para mantener la alineación

                      const SizedBox(height: 4),

                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: GoogleFonts.fredoka(
                              fontSize: isLowTime ? 24 : 22,
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
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.pause, color: Colors.white, size: 24),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
