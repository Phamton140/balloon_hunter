// lib/screens/collection_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../managers/game_manager.dart';
import '../managers/save_manager.dart';
import '../utils/palette.dart';
import '../components/balloon_widget.dart';
import '../models/balloon_type.dart';

class _ItemConfig {
  final int requiredLevel;
  final Widget Function(int currentLevel) builder;
  _ItemConfig(this.requiredLevel, this.builder);
}

class CollectionScreen extends StatelessWidget {
  final GameManager gameManager;
  final VoidCallback onBack;

  const CollectionScreen({
    super.key,
    required this.gameManager,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final maxLevel = gameManager.saveManager.maxLevelReached;

    final allItems = [
      _ItemConfig(1, (cl) => _buildThemeItem(name: 'Tema 1: Naturaleza', requiredLevel: 1, currentLevel: cl, previewAsset: 'assets/images/bg_afternoon.png')),
      _ItemConfig(10, (cl) => _buildBalloonItem(name: 'Globo de Hielo', description: 'Ralentiza el tiempo temporalmente.', requiredLevel: 10, currentLevel: cl, type: BalloonType.blue)),
      _ItemConfig(20, (cl) => _buildThemeItem(name: 'Tema 2: Desierto', requiredLevel: 20, currentLevel: cl, previewAsset: 'assets/images/bg_afternoon_2.jpg')),
      _ItemConfig(30, (cl) => _buildBalloonItem(name: 'Globo Bomba', description: 'Explota todos los globos en pantalla.', requiredLevel: 30, currentLevel: cl, type: BalloonType.black)),
      _ItemConfig(40, (cl) => _buildThemeItem(name: 'Tema 3: Colinas', requiredLevel: 40, currentLevel: cl, previewAsset: 'assets/images/bg_afternoon_3.png')),
      _ItemConfig(50, (cl) => _buildBalloonItem(name: 'Globo Reloj', description: 'Resta 5 segundos al temporizador.', requiredLevel: 50, currentLevel: cl, type: BalloonType.clock)),
      _ItemConfig(60, (cl) => _buildBalloonItem(name: 'Globo Blindado', description: 'Requiere 3 toques para explotar.', requiredLevel: 60, currentLevel: cl, type: BalloonType.armored)),
    ];

    int visibleCount = 0;
    for (int i = 0; i < allItems.length; i++) {
      if (maxLevel > allItems[i].requiredLevel) {
        visibleCount++;
      } else {
        visibleCount += 3;
        break;
      }
    }
    if (visibleCount > allItems.length) visibleCount = allItems.length;

    final visibleItems = allItems.take(visibleCount).map((c) => c.builder(maxLevel)).toList();

    return Container(
      decoration: const BoxDecoration(
        gradient: Palette.menuGradient,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 32),
                    onPressed: onBack,
                  ),
                  Expanded(
                    child: Text(
                      'PROGRESO',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fredoka(
                        fontSize: 32,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance for back button
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Nivel Máximo Alcanzado: $maxLevel',
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  fontSize: 20,
                  color: Colors.yellowAccent,
                ),
              ),
              const SizedBox(height: 24),

              // Contenido scrolleable
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildSectionTitle('Recompensas por Nivel'),
                    ...visibleItems,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.fredoka(
          fontSize: 24,
          color: Colors.white70,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildBalloonItem({
    required String name,
    required String description,
    required int requiredLevel,
    required int currentLevel,
    BalloonType? type,
    Color? fallbackColor,
    IconData? fallbackIcon,
  }) {
    final isUnlocked = currentLevel > requiredLevel;
    final color = type?.color ?? fallbackColor ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnlocked ? color.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked ? color.withValues(alpha: 0.5) : Colors.white12,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Ícono o Globo dibujado estáticamente
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isUnlocked ? Colors.transparent : Colors.black54,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: isUnlocked
                ? (type != null
                    ? BalloonWidget(type: type, width: 45, height: 55)
                    : Icon(fallbackIcon, color: Colors.white, size: 30))
                : const Icon(Icons.lock, color: Colors.white38, size: 30),
          ),
          const SizedBox(width: 16),
          // Textos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUnlocked ? name : '???',
                  style: GoogleFonts.fredoka(
                    fontSize: 20,
                    color: isUnlocked ? Colors.white : Colors.white54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isUnlocked ? description : 'Completa el nivel $requiredLevel para desbloquear.',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeItem({
    required String name,
    required int requiredLevel,
    required int currentLevel,
    required String previewAsset,
  }) {
    final isUnlocked = currentLevel > requiredLevel;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked ? Colors.green.withValues(alpha: 0.5) : Colors.white12,
          width: 2,
        ),
        image: isUnlocked
            ? DecorationImage(
                image: AssetImage(previewAsset),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.3),
                  BlendMode.darken,
                ),
              )
            : null,
        color: isUnlocked ? null : Colors.white.withValues(alpha: 0.05),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUnlocked ? Icons.landscape : Icons.lock,
              color: isUnlocked ? Colors.white : Colors.white38,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              isUnlocked ? name : 'Tema Desconocido',
              style: GoogleFonts.fredoka(
                fontSize: 22,
                color: isUnlocked ? Colors.white : Colors.white54,
              ),
            ),
            if (!isUnlocked)
              Text(
                'Completa el nivel $requiredLevel',
                style: const TextStyle(color: Colors.white54),
              ),
          ],
        ),
      ),
    );
  }
}
