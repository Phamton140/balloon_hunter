// lib/screens/main_menu_screen.dart
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../managers/game_manager.dart';
import '../managers/save_manager.dart';
import '../screens/game_over_screen.dart'; // Added for _LevelSelectionDialog

class MainMenuScreen extends StatefulWidget {
  final GameManager gameManager;
  final VoidCallback? onNewGame;
  final VoidCallback? onResume;
  final VoidCallback? onRanking;
  final VoidCallback? onSettings;
  final VoidCallback? onCollection;
  final VoidCallback? onExit;

  const MainMenuScreen({
    super.key,
    required this.gameManager,
    this.onNewGame,
    this.onResume,
    this.onRanking,
    this.onSettings,
    this.onCollection,
    this.onExit,
  });

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MenuBalloonData {
  double x;
  double y;
  double speed;
  Color color;
  _MenuBalloonData(this.x, this.y, this.speed, this.color);
}

class _MainMenuScreenState extends State<MainMenuScreen> with TickerProviderStateMixin {
  late AnimationController _tickerController;
  final List<_MenuBalloonData> _balloons = [];
  final Random _rnd = Random();
  
  @override
  void initState() {
    super.initState();
    
    final colors = [
      const Color(0xAAFFD600),
      const Color(0xAA43E97B),
      const Color(0xAAFF4757),
      const Color(0xAA00B4D8),
    ];
    
    for (int i = 0; i < 8; i++) {
      _balloons.add(_MenuBalloonData(
        _rnd.nextDouble(),
        _rnd.nextDouble() * 1.2,
        0.1 + _rnd.nextDouble() * 0.3,
        colors[_rnd.nextInt(colors.length)]
      ));
    }
    
    _tickerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    
    _tickerController.addListener(() {
      setState(() {
        for (final b in _balloons) {
          b.y -= b.speed * 0.016; 
          if (b.y < -0.2) {
             b.y = 1.2;
             b.x = _rnd.nextDouble();
             b.speed = 0.1 + _rnd.nextDouble() * 0.3;
             b.color = colors[_rnd.nextInt(colors.length)];
          }
        }
      });
    });
  }
  
  @override
  void dispose() {
    _tickerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.gameManager.saveManager.currentTheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onExit?.call();
      },
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          image: DecorationImage(
            image: AssetImage('assets/images/menu_bg.jpg'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Globos decorativos que suben
              CustomPaint(
                painter: _MenuBalloonsPainter(_balloons),
                size: Size.infinite,
              ),
              
              // Iconos Top Right
              Positioned(
                top: 16,
                right: 16,
                child: Row(
                  children: [
                    // Bell icon
                    AnimatedBuilder(
                      animation: widget.gameManager.inboxManager,
                      builder: (context, _) {
                        final hasUnread = widget.gameManager.inboxManager.hasUnread;
                        return GestureDetector(
                          onTap: () => _showInboxDialog(context),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white24, width: 1),
                                ),
                                child: const Icon(Icons.notifications, color: Colors.white, size: 28),
                              ),
                              if (hasUnread)
                                Positioned(
                                  top: -2,
                                  right: -2,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.redAccent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${widget.gameManager.inboxManager.pendingRequests.length}',
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
                                ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 200.ms).scale();
                      }
                    ),
                    const SizedBox(width: 12),
                    // Settings icon
                    GestureDetector(
                      onTap: () => widget.onSettings?.call(),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24, width: 1),
                        ),
                        child: const Icon(Icons.settings, color: Colors.white, size: 28),
                      ),
                    ).animate().fadeIn(delay: 300.ms).scale(),
                  ],
                ),
              ),

              // Contenido Central
              Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Spacer(), // Empuja TODO hacia abajo lo máximo posible

                // Gran botón JUGAR
                GestureDetector(
                  onTap: _handlePlayTap,
                  child: Container(
                    width: 260,
                    height: 85,
                    decoration: BoxDecoration(
                      color: theme == AppTheme.wood ? null : null, // Fallback
                      gradient: theme != AppTheme.wood 
                        ? const LinearGradient(
                            colors: [Color(0xFF43E97B), Color(0xFF38F9D7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ) 
                        : null,
                      image: theme == AppTheme.wood 
                        ? const DecorationImage(
                            image: AssetImage('assets/images/ui/wood_bg.jpg'),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(Color(0xFFE53935), BlendMode.hardLight),
                          )
                        : null,
                      borderRadius: BorderRadius.circular(45),
                      boxShadow: theme == AppTheme.wood 
                          ? const [BoxShadow(color: Color(0x66000000), offset: Offset(0, 6), blurRadius: 0)]
                          : [
                              BoxShadow(
                                color: const Color(0xFF43E97B).withValues(alpha: 0.5),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                      border: theme == AppTheme.wood 
                          ? Border.all(color: const Color(0xFF3E2723), width: 4)
                          : Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
                    ),
                    child: Center(
                      child: Text(
                        'JUGAR',
                        style: GoogleFonts.fredoka(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                          shadows: theme == AppTheme.wood 
                              ? const [Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 3))]
                              : const [Shadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 2))],
                        ),
                      ),
                    ),
                  ),
                ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                 .scaleXY(begin: 1.0, end: 1.05, duration: 1200.ms, curve: Curves.easeInOutSine),

                const SizedBox(height: 20),

                // Botones pequeños de Progreso y Ranking
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    children: [
                      Expanded(
                        child: _GlassButton(
                          icon: Icons.star_rounded,
                          label: 'PROGRESO',
                          color: const Color(0xFF43E97B),
                          theme: theme,
                          woodAsset: 'assets/images/ui/btn_wood_green.jpg',
                          onTap: () => widget.onCollection?.call(),
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _GlassButton(
                          icon: Icons.leaderboard_rounded,
                          label: 'RANKING',
                          color: const Color(0xFF00B4D8),
                          theme: theme,
                          woodAsset: 'assets/images/ui/btn_wood_blue.jpg',
                          onTap: () => widget.onRanking?.call(),
                        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Tarjeta de Google Play (pegada al fondo)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: _GooglePlayCard(gameManager: widget.gameManager).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
                ),
              ],
            ),
          ],
        ),
      ),
    ));
  }

  void _showInboxDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
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
          child: AnimatedBuilder(
            animation: widget.gameManager.inboxManager,
            builder: (context, _) {
              final requests = widget.gameManager.inboxManager.pendingRequests;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'NOTIFICACIONES',
                    style: GoogleFonts.fredoka(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (requests.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('No tienes solicitudes pendientes.', style: GoogleFonts.fredoka(color: Colors.white70)),
                    )
                  else
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        itemCount: requests.length,
                        itemBuilder: (context, i) {
                          final r = requests[i];
                          return ListTile(
                            leading: const Icon(Icons.person, color: Colors.white),
                            title: Text(r.fromPlayerName, style: GoogleFonts.fredoka(color: Colors.white)),
                            subtitle: Text('Quiere ser tu amigo', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check_circle, color: Colors.greenAccent),
                                  onPressed: () => widget.gameManager.inboxManager.respondToRequest(r.id, r.fromPlayerId, true),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.cancel, color: Colors.redAccent),
                                  onPressed: () => widget.gameManager.inboxManager.respondToRequest(r.id, r.fromPlayerId, false),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white24,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('CERRAR'),
                  )
                ],
              );
            },
          ),
        ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
      ),
    );
  }

  void _handlePlayTap() {
    if (widget.gameManager.hasSavedGame) {
      showDialog(
        context: context,
        barrierColor: Colors.black87,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎈', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(
                  'PARTIDA EN CURSO',
                  style: GoogleFonts.fredoka(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Nivel: ${widget.gameManager.saveManager.savedLevel}\nPuntuación: ${widget.gameManager.saveManager.savedScore}',
                  style: GoogleFonts.fredoka(fontSize: 18, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onNewGame?.call();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('NUEVA', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onResume?.call();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF43E97B),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('CONTINUAR', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
        ),
      );
    } else {
      showDialog(
        context: context,
        barrierColor: Colors.black87,
builder: (context) => LevelSelectionDialog(
          maxLevelReached: widget.gameManager.saveManager.maxLevelReached,
          onLevelSelected: (startLevel) {
            if (Navigator.canPop(context)) Navigator.of(context).pop();
            widget.gameManager.startNewGame(startLevel: startLevel);
          },
        ),
      );
    }
  }
}

class _GooglePlayCard extends StatefulWidget {
  final GameManager gameManager;
  const _GooglePlayCard({required this.gameManager});

  @override
  State<_GooglePlayCard> createState() => _GooglePlayCardState();
}

class _GooglePlayCardState extends State<_GooglePlayCard> {
  @override
  Widget build(BuildContext context) {
    final cloud = widget.gameManager.cloudSyncManager;
    final isLinked = cloud.isGoogleLinked;
    final user = cloud.currentUser;
    final theme = widget.gameManager.saveManager.currentTheme;

    final cardContent = GestureDetector(
      onTap: () async {
            if (isLinked) {
              final bool? disconnect = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF202020),
                  title: Text('Desconectar Cuenta', style: GoogleFonts.fredoka(color: Colors.white)),
                  content: const Text('¿Estás seguro de que quieres desconectar tu cuenta de Google?', style: TextStyle(color: Colors.white70)),
                  actions: [
                    TextButton(onPressed: () => Navigator.canPop(ctx) ? Navigator.pop(ctx, false) : null, child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
                    ElevatedButton(
                      onPressed: () => Navigator.canPop(ctx) ? Navigator.pop(ctx, true) : null,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Desconectar', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
              
              if (disconnect == true && mounted) {
                await widget.gameManager.cloudSyncManager.signOutGoogle();
                setState(() {});
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme == AppTheme.wood 
                  ? const Color(0xFF24160F).withValues(alpha: 0.92)
                  : const Color(0xFF151428).withValues(alpha: 0.85),
              image: theme == AppTheme.wood 
                  ? const DecorationImage(
                      image: AssetImage('assets/images/ui/wood_bg.jpg'),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(Color(0xB31F1008), BlendMode.darken),
                    )
                  : null,
              borderRadius: BorderRadius.circular(20),
              border: theme == AppTheme.wood 
                  ? Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.6), width: 1.5)
                  : Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
              boxShadow: const [
                BoxShadow(color: Color(0x66000000), offset: Offset(0, 4), blurRadius: 8),
              ],
            ),
            child: Row(
              children: [
                // Avatar
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  image: isLinked && user?.photoURL != null
                      ? DecorationImage(image: NetworkImage(user!.photoURL!), fit: BoxFit.cover)
                      : null,
                ),
                child: (isLinked && user?.photoURL != null)
                    ? null
                    : Icon(Icons.person, color: Colors.white.withOpacity(0.7), size: 28),
              ),
              const SizedBox(width: 12),
              
              // Textos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLinked) ...[
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user?.displayName ?? 'Jugador Conectado',
                              style: GoogleFonts.fredoka(
                                color: Colors.white, 
                                fontSize: 16, 
                                fontWeight: FontWeight.w500,
                                shadows: theme == AppTheme.wood ? const [Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 2))] : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF43E97B), shape: BoxShape.circle)),
                        ],
                      ),
                      Text(
                        'Progreso protegido en la nube', 
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9), 
                          fontSize: 12,
                          shadows: theme == AppTheme.wood ? const [Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 2))] : null,
                        )
                      ),
                    ] else ...[
                      Text(
                        'Protege tu progreso', 
                        style: GoogleFonts.fredoka(
                          color: Colors.white, 
                          fontSize: 16, 
                          fontWeight: FontWeight.w500,
                          shadows: theme == AppTheme.wood ? const [Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 2))] : null,
                        )
                      ),
                      Text(
                        'Conecta tu cuenta para no perder nada.', 
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9), 
                          fontSize: 12,
                          shadows: theme == AppTheme.wood ? const [Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 2))] : null,
                        )
                      ),
                    ],
                  ],
                ),
              ),

              // Botones de Conectar (solo si no está vinculado)
              if (!isLinked)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        bool success = await widget.gameManager.linkGoogleAccount();
                        if (mounted) {
                          setState(() {});
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('¡Cuenta de Google vinculada con éxito!'),
                                backgroundColor: Color(0xFF43E97B),
                                duration: Duration(seconds: 3),
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: theme == AppTheme.wood ? const [BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))] : null,
                        ),
                        alignment: Alignment.center,
                        child: FaIcon(
                          FontAwesomeIcons.google, 
                          color: const Color(0xFFDB4437), 
                          size: 22,
                          shadows: theme == AppTheme.wood ? const [Shadow(color: Colors.black45, blurRadius: 2, offset: Offset(0, 1))] : null,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      );

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: theme == AppTheme.wood 
          ? cardContent
          : BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: cardContent,
            ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final AppTheme theme;
  final String? woodAsset;
  final VoidCallback onTap;

  const _GlassButton({required this.icon, required this.label, required this.color, required this.theme, this.woodAsset, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final buttonContent = Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: theme == AppTheme.wood ? null : color.withValues(alpha: 0.15),
        image: theme == AppTheme.wood 
            ? DecorationImage(
                image: const AssetImage('assets/images/ui/wood_bg.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(color, BlendMode.hardLight),
              )
            : null,
        borderRadius: BorderRadius.circular(20),
        border: theme == AppTheme.wood 
            ? Border.all(color: const Color(0xFF3E2723), width: 3)
            : Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: theme == AppTheme.wood 
            ? const [BoxShadow(color: Color(0x66000000), offset: Offset(0, 4), blurRadius: 0)]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: theme == AppTheme.wood ? Colors.white : color, size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.fredoka(
              fontSize: 16, 
              color: Colors.white, 
              fontWeight: FontWeight.bold,
              shadows: theme == AppTheme.wood 
                 ? const [Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 2))]
                 : null,
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: theme == AppTheme.wood 
            ? buttonContent
            : BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                child: buttonContent,
              ),
      ),
    );
  }
}

class _MenuBalloonsPainter extends CustomPainter {
  final List<_MenuBalloonData> balloons;
  _MenuBalloonsPainter(this.balloons);
  
  @override
  void paint(Canvas canvas, Size size) {
    for (final b in balloons) {
      final paint = Paint()..color = b.color;
      final x = b.x * size.width;
      final y = b.y * size.height;
      
      canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 40, height: 52), paint);
      
      final highlightPaint = Paint()..color = Colors.white.withOpacity(0.4);
      canvas.drawOval(Rect.fromCenter(center: Offset(x - 8, y - 10), width: 10, height: 16), highlightPaint);

      canvas.drawCircle(Offset(x, y + 26), 5, paint);
      
      final stringPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
        
      final path = Path();
      path.moveTo(x, y + 28);
      path.quadraticBezierTo(
        x + sin(y * 0.05) * 10, y + 40,
        x - sin(y * 0.05) * 5, y + 60
      );
      canvas.drawPath(path, stringPaint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
