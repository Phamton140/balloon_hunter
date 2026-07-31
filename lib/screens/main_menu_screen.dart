// lib/screens/main_menu_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../managers/game_manager.dart';

class MainMenuScreen extends StatefulWidget {
  final GameManager gameManager;
  final VoidCallback? onNewGame;
  final VoidCallback? onResume;
  final VoidCallback? onRanking;
  final VoidCallback? onSettings;
  const MainMenuScreen({
    super.key,
    required this.gameManager,
    this.onNewGame,
    this.onResume,
    this.onRanking,
    this.onSettings,
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
    
    // Generar globos iniciales repartidos por la pantalla
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
          b.y -= b.speed * 0.016; // Movimiento hacia arriba
          
          if (b.y < -0.2) {
             // Reset al fondo
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black, // Para rellenar el espacio sobrante
        image: DecorationImage(
          image: AssetImage('assets/images/menu_bg.png'),
          fit: BoxFit.cover, // Ajuste perfecto para vertical 9:16
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
            
            // Contenido principal (Botones, ya que el título está en la imagen)
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Spacer(flex: 5), // Empuja los botones mucho más abajo
                
                // Play button
                _MenuButton(
                  label: '🎈 JUGAR',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF43E97B), Color(0xFF38F9D7)],
                  ),
                  onTap: _handlePlayTap,
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                
                const SizedBox(height: 16),
                
                // Records button
                _MenuButton(
                  label: '🏆 RÉCORDS',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                  ),
                  onTap: () => widget.onRanking?.call(),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                
                const SizedBox(height: 16),
                
                // Settings button
                _MenuButton(
                  label: '⚙️ AJUSTES',
                  gradient: LinearGradient(
                    colors: [Colors.grey.shade600, Colors.grey.shade800],
                  ),
                  onTap: () => widget.onSettings?.call(),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                
                const Spacer(flex: 1), // Espacio abajo
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handlePlayTap() {
    if (widget.gameManager.hasSavedGame) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: Text(
            'Partida en progreso',
            style: GoogleFonts.fredoka(color: Colors.white),
          ),
          content: Text(
            '¿Desea continuar con la partida anterior?\n\nNivel: ${widget.gameManager.saveManager.savedLevel}\nPuntuación: ${widget.gameManager.saveManager.savedScore}',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onNewGame?.call();
              },
              child: const Text('NUEVA PARTIDA', style: TextStyle(color: Colors.redAccent)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onResume?.call();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF43E97B)),
              child: const Text('CONTINUAR', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      );
    } else {
      widget.onNewGame?.call();
    }
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
      
      // Cuerpo del globo
      canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 40, height: 52), paint);
      
      // Brillo especular
      final highlightPaint = Paint()..color = Colors.white.withValues(alpha: 0.4);
      canvas.drawOval(Rect.fromCenter(center: Offset(x - 8, y - 10), width: 10, height: 16), highlightPaint);

      // Nudo
      canvas.drawCircle(Offset(x, y + 26), 5, paint);
      
      // Hilo
      final stringPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
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

class _MenuButton extends StatelessWidget {
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _MenuButton({required this.label, required this.gradient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Hacemos el gradiente semi-transparente para ver el fondo
    final transparentGradient = LinearGradient(
      colors: gradient.colors.map((c) => c.withValues(alpha: 0.75)).toList(),
      begin: gradient.begin,
      end: gradient.end,
    );
    
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: Container(
          width: 240,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: transparentGradient,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.fredoka(
                fontSize: 20,
                color: Colors.white,
                shadows: [const Shadow(color: Colors.black26, blurRadius: 4)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
