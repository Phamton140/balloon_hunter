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
            // -- Barra superior (Unificada) --
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
    // SafeArea padding
    final topPadding = MediaQuery.of(context).padding.top;
    
    return Container(
      // Sin margen arriba, usando el padding para el SafeArea
      padding: EdgeInsets.only(
        top: topPadding > 0 ? topPadding + 8 : 12, 
        bottom: 12, 
        left: 16, 
        right: 16
      ),
      decoration: BoxDecoration(
        color: Palette.hudBackground,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        border: Border(
          bottom: BorderSide(
            color: isSlowMo ? Palette.balloonBlue.withOpacity(0.6) : Colors.white.withOpacity(0.1),
            width: isSlowMo ? 2 : 1,
          )
        ),
        boxShadow: [
          BoxShadow(
            color: isSlowMo ? Palette.balloonBlue.withOpacity(0.3) : Colors.black38,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fila 1: Stats principales
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Score
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🏆 $bestScore',
                    style: GoogleFonts.fredoka(
                      fontSize: 11,
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
              
              const Spacer(),

              // Nivel y slow mo
              Column(
                children: [
                  if (isSlowMo)
                    Text('❄ SLOW', style: GoogleFonts.fredoka(fontSize: 11, color: Palette.balloonBlue))
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

              const Spacer(),

              // Timer + Pausa
              Row(
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: GoogleFonts.fredoka(
                      fontSize: isLowTime ? 24 : 20,
                      fontWeight: FontWeight.bold,
                      color: isLowTime ? Palette.hudDanger : Palette.hudText,
                    ),
                    child: Text('⏱ $timeStr'),
                  ).animate(
                    target: isLowTime ? 1 : 0,
                  ).shake(hz: 3, duration: 500.ms),

                  const SizedBox(width: 12),

                  GestureDetector(
                    onTap: onPause,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.pause, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Fila 2: Escapados y Combo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Globos escapados
              Row(
                children: [
                  Text(
                    'Escapados: ',
                    style: GoogleFonts.fredoka(
                      fontSize: 13,
                      color: Palette.hudText.withOpacity(0.8),
                    ),
                  ),
                  ...List.generate(GameConstants.maxEscapedBalloons, (i) {
                    final isEscaped = i < escaped;
                    return Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isEscaped ? Palette.hudDanger : Colors.white24,
                        ),
                        child: Center(
                          child: Text(
                            isEscaped ? '💨' : '',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),

              // Combo
              if (combo >= GameConstants.comboThreshold1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B35), Color(0xFFFFD600)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '💥 COMBO x${combo >= GameConstants.comboThreshold3 ? '3.0' : combo >= GameConstants.comboThreshold2 ? '2.0' : '1.5'}',
                    style: GoogleFonts.fredoka(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.08, 1.08), duration: 600.ms)
              else
                const SizedBox(height: 24), // Para mantener la altura cuando no hay combo
            ],
          ),
        ],
      ),
    );
  }
}
