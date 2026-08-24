// lib/utils/palette.dart
// Paleta de colores y tema visual del juego

import 'package:flutter/material.dart';

/// Paleta de colores centralizada para toda la UI y los componentes del juego
class Palette {
  // -- Colores de globos --
  static const Color balloonYellow = Color(0xFFFFD600);
  static const Color balloonYellowGlow = Color(0xFFFFF176);
  static const Color balloonGreen = Color(0xFF43E97B);
  static const Color balloonGreenGlow = Color(0xFFA8FF78);
  static const Color balloonRed = Color(0xFFFF4757);
  static const Color balloonRedGlow = Color(0xFFFF6B81);
  static const Color balloonBlue = Color(0xFF00B4D8);
  static const Color balloonBlueGlow = Color(0xFF90E0EF);
  // -- Globo Bomba (Negro con borde rojo/neón) --
  static const Color balloonBlack = Color(0xFF1E1E1E); 
  static const Color balloonBlackGlow = Color(0xFFFF0055); 

  // -- Globo Reloj (Blanco) --
  static const Color balloonClock = Color(0xFFF5F5F5); 
  static const Color balloonClockGlow = Color(0xFFB0BEC5);
  static const Color particleClock = Color(0xFFF9A826); 

  // -- Globo Blindado --
  static const Color armoredPremium = Color(0xFF9B59B6); // Morado brillante
  static const Color armoredPremiumGlow = Color(0xFFFFFFFF);
  static const Color armoredDamaged = Color(0xFF8E44AD); // Morado dañado
  static const Color armoredDamagedGlow = Color(0xFFE1BEE7);

  // -- Partículas de explosión por tipo --
  static const Color particleYellow = Color(0xFFFFD600);
  static const Color particleGreen = Color(0xFF43E97B);
  static const Color particleRed = Color(0xFFFF4757);
  static const Color particleBlue = Color(0xFF00B4D8);
  static const Color particleBlack = Color(0xFF9B59B6);

  // -- Fondo del juego --
  static const Color skyTop = Color(0xFF87CEEB);
  static const Color skyBottom = Color(0xFFE0F4FF);

  // -- UI - HUD --
  static const Color hudBackground = Color(0xCC1A1A2E);
  static const Color hudText = Color(0xFFFFFFFF);
  static const Color hudAccent = Color(0xFFFFD600);
  static const Color hudCombo = Color(0xFFFF6B35);
  static const Color hudDanger = Color(0xFFFF4757);

  // -- UI - Menú y pantallas --
  static const Color menuBackground = Color(0xFF0F3460);
  static const Color menuGradientTop = Color(0xFF16213E);
  static const Color menuGradientBottom = Color(0xFF0F3460);
  static const Color menuAccent = Color(0xFFE94560);
  static const Color menuText = Color(0xFFFFFFFF);
  static const Color menuSubtext = Color(0xFFB0BEC5);
  static const Color menuCard = Color(0x1AFFFFFF);
  static const Color menuCardBorder = Color(0x33FFFFFF);

  // -- Botones --
  static const Color buttonPrimary = Color(0xFF4CAF50);
  static const Color buttonPrimaryGlow = Color(0xFF81C784);
  static const Color buttonDanger = Color(0xFFE94560);
  static const Color buttonSecondary = Color(0xFF546E7A);

  // -- Estrellas --
  static const Color starActive = Color(0xFFFFD600);
  static const Color starInactive = Color(0xFF546E7A);

  // -- Medallas ranking --
  static const Color medalGold = Color(0xFFFFD700);
  static const Color medalSilver = Color(0xFFC0C0C0);
  static const Color medalBronze = Color(0xFFCD7F32);

  // -- Efecto hielo (globo azul) --
  static const Color iceOverlay = Color(0x3300B4D8);
  static const Color iceBorder = Color(0xFF00B4D8);

  // -- Gradiente principal UI --
  static const LinearGradient menuGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [menuGradientTop, menuGradientBottom],
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
  );
}
