// lib/screens/game_over_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../managers/game_manager.dart';
import '../managers/ad_manager.dart';
import '../utils/palette.dart';

class GameOverScreen extends StatefulWidget {
  final GameManager gameManager;
  final bool birdHit;
  final VoidCallback? onPlayAgain;
  final VoidCallback? onRevive;
  final VoidCallback? onMenu;

  const GameOverScreen({
    super.key,
    required this.gameManager,
    this.birdHit = false,
    this.onPlayAgain,
    this.onRevive,
    this.onMenu,
  });

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen> {
  @override
  void initState() {
    super.initState();
    // Reintentar cargar el anuncio si no está listo al abrir esta pantalla
    if (!AdManager().isRewardedAdLoaded) {
      AdManager().loadRewardedAd();
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameManager = widget.gameManager;
    // Si NO fue por dejar escapar 3 globos, entonces fue por chocar un pájaro.
    final birdHit = !gameManager.levelManager.isGameOver;
    final onPlayAgain = widget.onPlayAgain;
    final onRevive = widget.onRevive;
    final onMenu = widget.onMenu;
    
    final score = gameManager.scoreManager.score;
    final level = gameManager.levelManager.currentLevel;
    final accuracy = gameManager.scoreManager.accuracy;
    final maxCombo = gameManager.scoreManager.maxCombo;
    final destroyed = gameManager.scoreManager.balloonsDestroyed;
    final bestScore = gameManager.rankingManager.getBestScore();
    final isNewRecord = score > bestScore;

    return Container(
      decoration: const BoxDecoration(
        gradient: Palette.menuGradient,
      ),
      child: SafeArea(
        child: ListenableBuilder(
          listenable: gameManager,
          builder: (context, child) {
            return Stack(
              children: [
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 90),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Colors.orange, Colors.red, Colors.deepPurple],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: Text(
                            'GAME OVER',
                            style: GoogleFonts.fredoka(
                              fontSize: 54,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              shadows: [const Shadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4))],
                            ),
                          ),
                        ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(1.3, 1.3), curve: Curves.easeOutBack),

                        const SizedBox(height: 8),
                        Text(
                          birdHit ? '¡Golpeaste un ave!' : '¡Dejaste escapar 3 globos!',
                          style: GoogleFonts.fredoka(fontSize: 18, color: Colors.orangeAccent),
                        ).animate().fadeIn(delay: 300.ms),

                        if (isNewRecord) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: Palette.goldGradient,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '🏆 ¡NUEVO RÉCORD!',
                              style: GoogleFonts.fredoka(fontSize: 16, color: Colors.white),
                            ),
                          ).animate(onPlay: (c) => c.repeat(reverse: true))
                              .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.05, 1.05), duration: 600.ms),
                        ],

                        const SizedBox(height: 16),

                        // Stats
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            children: [
                              _GOStatRow('⭐ Puntuación final', '$score'),
                              _GOStatRow('📈 Nivel alcanzado', '$level'),
                              _GOStatRow('🎈 Globos destruidos', '$destroyed'),
                              _GOStatRow('🎯 Precisión', '${accuracy.toStringAsFixed(1)}%'),
                              _GOStatRow('💥 Combo máximo', 'x$maxCombo'),
                              if (bestScore > 0)
                                _GOStatRow('🏆 Mejor puntuación', '$bestScore'),
                            ],
                          ),
                        ).animate().fadeIn(delay: 500.ms),

                        const SizedBox(height: 20),

                        // Botón de revivir (arriba)
                        AnimatedBuilder(
                          animation: AdManager(),
                          builder: (context, child) {
                            if (AdManager().isRewardedAdLoaded) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _GOButton(
                                  label: '🎬 REVIVIR NIVEL',
                                  gradient: const LinearGradient(colors: [Palette.balloonGreen, Color(0xFF00B09B)]),
                                  onTap: () {
                                    AdManager().showRewardedAd(onRewardEarned: () {
                                      onRevive?.call();
                                    });
                                  },
                                ).animate().scale(delay: 700.ms),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),

                        // Play again (debajo)
                        _GOButton(
                          label: 'NUEVA PARTIDA',
                          gradient: const LinearGradient(colors: [Palette.menuAccent, Color(0xFFFF6B81)]),
                          onTap: () => onPlayAgain?.call(),
                        ).animate().fadeIn(delay: 800.ms),

                        const SizedBox(height: 24), // Espaciado agregado

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _SmallGOButton(
                              label: '📤 Compartir',
                              onTap: () => _share(score, level),
                            ),
                            const SizedBox(width: 12),
                            _SmallGOButton(
                              label: '🏠 Menú',
                              onTap: () => onMenu?.call(),
                            ),
                          ],
                        ).animate().fadeIn(delay: 800.ms),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: IconButton(
                      icon: Icon(
                        gameManager.audioManager.masterVolume > 0 
                            ? Icons.volume_up_rounded 
                            : Icons.volume_off_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () async {
                        if (gameManager.audioManager.masterVolume > 0) {
                          await gameManager.audioManager.setMasterVolume(0.0);
                        } else {
                          await gameManager.audioManager.setMasterVolume(1.0);
                        }
                        // ignore: invalid_use_of_protected_member
                        (gameManager as dynamic).notifyListeners?.call();
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _share(int score, int level) {
    Share.share(
      '🎈 Jugué Balloon Hunter hasta el Nivel $level con $score puntos.\n'
      '¿Puedes superarme? ¡Descarga el juego! 🎮',
      subject: 'Balloon Hunter - Mi puntuación',
    );
  }
}

class _GOStatRow extends StatelessWidget {
  final String label;
  final String value;
  const _GOStatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.fredoka(fontSize: 14, color: Colors.white60)),
        Text(value, style: GoogleFonts.fredoka(fontSize: 14, color: Colors.white)),
      ],
    ),
  );
}

class _GOButton extends StatelessWidget {
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;
  const _GOButton({required this.label, required this.gradient, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 260, // Ancho fijo para que ambos botones midan lo mismo
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: gradient.colors.first.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: Text(label, style: GoogleFonts.fredoka(fontSize: 18, color: Colors.white)),
    ),
  );
}

class _SmallGOButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SmallGOButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(label, style: GoogleFonts.fredoka(fontSize: 14, color: Colors.white70)),
    ),
  );
}
