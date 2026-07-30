import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../managers/game_manager.dart';

class CountdownScreen extends StatefulWidget {
  final GameManager gameManager;
  final VoidCallback onCountdownComplete;

  const CountdownScreen({
    super.key,
    required this.gameManager,
    required this.onCountdownComplete,
  });

  @override
  State<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen> {
  Timer? _timer;
  int _countdown = 3;

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
        widget.onCountdownComplete();
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
    return Container(
      color: Colors.black54,
      child: Center(
        child: Text(
          '$_countdown',
          key: ValueKey<int>(_countdown),
          style: GoogleFonts.fredoka(
            fontSize: 120,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              const Shadow(color: Colors.black, blurRadius: 20),
            ],
          ),
        ).animate(key: ValueKey<int>(_countdown)).scale(
          duration: 400.ms, 
          curve: Curves.elasticOut,
          begin: const Offset(0.5, 0.5),
        ).fadeOut(
          delay: 500.ms,
          duration: 400.ms,
        ),
      ),
    );
  }
}
