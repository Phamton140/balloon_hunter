// lib/utils/constants.dart
// Constantes globales del juego Balloon Hunter

/// Configuración de pantalla y física
class GameConstants {
  // -- Pantalla --
  static const double referenceWidth = 450.0;
  static const double referenceHeight = 800.0;

  // -- Globos normales: velocidades base (px/s) --
  static const double balloonSpeedYellow = 80.0;
  static const double balloonSpeedGreen = 130.0;
  static const double balloonSpeedRed = 180.0;

  // -- Globos especiales: velocidades base --
  static const double balloonSpeedBlue = 75.0;
  static const double balloonSpeedBlack = 85.0;

  // -- Variación aleatoria de velocidad ±10% --
  static const double speedVariationMin = 0.90;
  static const double speedVariationMax = 1.10;

  // -- Oscilación horizontal (viento) --
  static const double oscillationAmplitudeMin = 8.0;
  static const double oscillationAmplitudeMax = 25.0;
  static const double oscillationFreqMin = 0.8;
  static const double oscillationFreqMax = 2.0;

  // -- Tamaño de globos --
  static const double balloonWidth = 70.0;
  static const double balloonHeight = 90.0;

  // -- Aves --
  static const double birdWidth = 80.0;
  static const double birdHeight = 55.0;
  static const double birdSpeedMin = 100.0;
  static const double birdSpeedMax = 200.0;

  // -- Duración del nivel en segundos --
  static const double levelDuration = 60.0;

  // -- Interfaz de Usuario --
  static const double hudHeight = 50.0; // Altura del HUD superior ultra-compacto

  // -- Globos escapados para Game Over --
  static const int maxEscapedBalloons = 3;

  // -- Sistema de estrellas --
  static const int starsThreeStars = 0; // escapados
  static const int starsTwoStars = 1;
  static const int starsOneStar = 2;

  // -- Multiplicador de velocidad por cada nivel --
  static const double speedLevelIncrement = 0.20; // 20% más rápido por nivel
  static const int speedLevelGroupSize = 1;

  // -- Combos --
  static const int comboThreshold1 = 3; // x1.5
  static const int comboThreshold2 = 5; // x2.0
  static const int comboThreshold3 = 8; // x3.0

  // -- Globo Azul (slow motion) --
  static const double slowMotionDuration = 5.0; // segundos
  static const double slowMotionMultiplier = 0.5;
  static const double blueSpecialDuration = 2.5; // segundos visible

  // -- Globo Negro --
  static const double blackSpecialDuration = 2.5; // segundos visible

  // -- Spawn --
  static const double spawnIntervalBase = 1.6; // segundos (más rápido desde el inicio)
  static const double spawnIntervalMin = 0.3;
  static const double spawnIntervalDecrement = 0.15; // disminuye más rápido por nivel

  // -- Object Pool: tamaños iniciales --
  static const int poolSizeBalloons = 12;
  static const int poolSizeBirds = 5;
  static const int poolSizeExplosions = 18;

  // -- Ranking --
  static const int rankingTopSize = 3;
  static const String rankingBoxName = 'balloon_hunter_ranking';

  // -- Overlay names --
  static const String overlayMainMenu = 'mainMenu';
  static const String overlayPause = 'pause';
  static const String overlayGameOver = 'gameOver';
  static const String overlayVictory = 'victory';
  static const String overlayRanking = 'ranking';
  static const String overlaySettings = 'settings';
  static const String overlayCountdown = 'countdown';
  static const String overlayReviveReady = 'reviveReady';
  static const String overlayHud = 'hud';
}
