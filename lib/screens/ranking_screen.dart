// lib/screens/ranking_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../managers/game_manager.dart';
import '../models/score_record.dart';
import '../utils/palette.dart';

class RankingScreen extends StatelessWidget {
  final GameManager gameManager;
  final VoidCallback? onPlay;
  final VoidCallback? onBack;

  const RankingScreen({
    super.key,
    required this.gameManager,
    this.onPlay,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final records = gameManager.rankingManager.getTopScores();
    final medals = [Palette.medalGold, Palette.medalSilver, Palette.medalBronze];
    final medalEmojis = ['🥇', '🥈', '🥉'];

    return Container(
      decoration: const BoxDecoration(gradient: Palette.menuGradient),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => onBack?.call(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '🏆 RÉCORDS',
                    style: GoogleFonts.fredoka(fontSize: 28, color: Colors.white),
                  ),
                ],
              ),
            ),

            Expanded(
              child: records.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🎈', style: TextStyle(fontSize: 60)),
                          const SizedBox(height: 16),
                          Text(
                            '¡Aún no hay récords!\nJuega tu primera partida.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.fredoka(fontSize: 18, color: Colors.white60),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: records.length,
                      itemBuilder: (context, i) {
                        final record = records[i];
                        return _RecordCard(
                          record: record,
                          position: i + 1,
                          medalColor: medals[i],
                          medalEmoji: medalEmojis[i],
                        ).animate(delay: Duration(milliseconds: i * 150)).fadeIn().slideX(begin: -0.3);
                      },
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: GestureDetector(
                onTap: () => onPlay?.call(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF43E97B), Color(0xFF38F9D7)]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      '🎈 JUGAR AHORA',
                      style: GoogleFonts.fredoka(fontSize: 20, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordCard extends StatefulWidget {
  final ScoreRecord record;
  final int position;
  final Color medalColor;
  final String medalEmoji;

  const _RecordCard({
    required this.record,
    required this.position,
    required this.medalColor,
    required this.medalEmoji,
  });

  @override
  State<_RecordCard> createState() => _RecordCardState();
}

class _RecordCardState extends State<_RecordCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.record;
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.medalColor.withOpacity(0.4),
            width: widget.position == 1 ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text(widget.medalEmoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${r.score} pts',
                        style: GoogleFonts.fredoka(fontSize: 24, color: Colors.white),
                      ),
                      Text(
                        'Nivel ${r.level} · ${_formatDate(r.date)}',
                        style: GoogleFonts.fredoka(fontSize: 12, color: Colors.white54),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white38,
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 12),
              Container(height: 1, color: Colors.white12),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MiniStat('🎈', '${r.balloonsDestroyed}', 'Destruidos'),
                  _MiniStat('🎯', '${r.accuracy.toStringAsFixed(0)}%', 'Precisión'),
                  _MiniStat('💥', 'x${r.maxCombo}', 'Combo máx.'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _MiniStat extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  const _MiniStat(this.icon, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        Text(value, style: GoogleFonts.fredoka(fontSize: 16, color: Colors.white)),
        Text(label, style: GoogleFonts.fredoka(fontSize: 10, color: Colors.white38)),
      ],
    );
  }
}
