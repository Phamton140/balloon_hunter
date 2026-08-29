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
  final Function(int startLevel) onPlayAgain; // Changed from VoidCallback
  final VoidCallback? onRevive;
  final VoidCallback? onMenu;

  const GameOverScreen({
    super.key,
    required this.gameManager,
    this.birdHit = false,
    required this.onPlayAgain, // Changed from VoidCallback
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
    final birdHit = widget.birdHit;
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

    final maxLevelReached = widget.gameManager.saveManager.maxLevelReached;

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

                        const SizedBox(height: 24),

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
      '¿Puedes superarme? ¡Descarga el juego! 🎮 \n',
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
        Text(label, style: GoogleFonts.fredoka(fontSize: 14, color: Colors.white)),
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

// Diálogo para seleccionar el nivel al empezar una nueva partida
class LevelSelectionDialog extends StatefulWidget {
  final int maxLevelReached;
  final Function(int startLevel)? onLevelSelected;
  final VoidCallback? onGameStart;
  final GameManager? gameManager; // Para acceder a AdManager y GameManager

  const LevelSelectionDialog({
    super.key,
    required this.maxLevelReached,
    this.onLevelSelected,
    this.onGameStart,
    this.gameManager,
  });

  @override
  State<LevelSelectionDialog> createState() => _LevelSelectionDialogState();
}

class _LevelSelectionDialogState extends State<LevelSelectionDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

@override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2C3E50), Color(0xFF000000)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white24, width: 2),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
              child: Stack(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'NUEVA PARTIDA',
                        style: GoogleFonts.fredoka(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      // Botón Nivel 1 (color globo verde)
                      _SimpleLevelButton(
                        label: 'Nivel 1',
                        subtitle: 'Empezar desde el principio',
                        color: Palette.balloonGreen,
                        onTap: () {
                          widget.onLevelSelected?.call(1);
                          widget.onGameStart?.call();
                          Navigator.of(context).pop();
                        },
                      ),
                      if (widget.maxLevelReached > 1) ...[
                        const SizedBox(height: 12),
                        // Botón Continuar - color dorado/amarillo (globo amarillo)
                        _SimpleLevelButton(
                          label: 'Continuar en Nivel ${widget.maxLevelReached}',
                          subtitle: 'Ver anuncio para continuar',
                          color: Palette.balloonYellow,
                          onTap: () async {
                            final adManager = AdManager();
                            
                            if (!adManager.isRewardedAdLoaded) {
                              adManager.loadRewardedAd();
                              await Future.delayed(const Duration(milliseconds: 500));
                            }
                            
                            if (!adManager.isRewardedAdLoaded) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('El anuncio no está disponible. Intenta más tarde.'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                              return;
                            }
                            
                            // Mostrar el Rewarded Ad directamente sin modal intermedio
                            adManager.showRewardedAd(onRewardEarned: () {
                              widget.onLevelSelected?.call(widget.maxLevelReached);
                              widget.onGameStart?.call();
                              Navigator.of(context).pop();
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                  // Botón X para cerrar
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white54, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
          ),
        );
      },
    );
  }
}

// Botón simple de nivel para el diálogo
class _SimpleLevelButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SimpleLevelButton({
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  /// Calcula si el color es claro para decidir color de texto
  bool get _isLightColor {
    // Luminancia percibida
    return (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) > 186;
  }

  Color get _textColor => _isLightColor ? Colors.black : Colors.white;
  Color get _subtitleColor => _isLightColor ? Colors.black54 : Colors.white70;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          onTap();
          // NO Navigator.pop() aquí - el callback ya lo maneja
        },
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withValues(alpha: 0.2),
        highlightColor: color.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.2),
                color.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 5,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.fredoka(
                        color: _textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.fredoka(
                        color: _subtitleColor,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

