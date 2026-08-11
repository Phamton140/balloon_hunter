// lib/main.dart
// Entry point de Balloon Hunter: conecta FlameGame con los overlays Flutter

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'balloon_hunter_game.dart';
import 'managers/ad_manager.dart';
import 'components/hud_component.dart';
import 'models/game_state.dart';
import 'screens/countdown_screen.dart';
import 'screens/game_over_screen.dart';
import 'screens/main_menu_screen.dart';
import 'screens/pause_screen.dart';
import 'screens/ranking_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/victory_screen.dart';
import 'screens/revive_ready_screen.dart';
import 'screens/collection_screen.dart';
import 'utils/constants.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Initialize AdManager without awaiting to avoid blocking the first frame
  AdManager().initialize();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final game = BalloonHunterGame();

  runApp(BalloonHunterApp(game: game));
}

class BalloonHunterApp extends StatelessWidget {
  final BalloonHunterGame game;

  const BalloonHunterApp({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Balloon Hunter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF43E97B),
          secondary: Color(0xFFFFD600),
          surface: Color(0xFF16213E),
        ),
        textTheme: GoogleFonts.fredokaTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
      ),
      home: _GameScreen(game: game),
    );
  }
}

/// Pantalla principal que contiene el GameWidget y gestiona los overlays
/// mediante un listener sobre el GameManager.
class _GameScreen extends StatefulWidget {
  final BalloonHunterGame game;

  const _GameScreen({required this.game});

  @override
  State<_GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<_GameScreen> {
  BalloonHunterGame get _game => widget.game;

  @override
  void initState() {
    super.initState();
    // Escuchar cambios de estado para actualizar overlays
    _game.gameManager.addListener(_onGameStateChanged);
  }

  @override
  void dispose() {
    _game.gameManager.removeListener(_onGameStateChanged);
    super.dispose();
  }

  void _onGameStateChanged() {
    if (!mounted) return;
    final state = _game.gameManager.state;
    _syncOverlays(state);
  }

  void _syncOverlays(GameState state) {
    // Cerrar todos los overlays que no corresponden al estado actual
    final allOverlays = [
      GameConstants.overlayMainMenu,
      GameConstants.overlayHud,
      GameConstants.overlayPause,
      GameConstants.overlayVictory,
      GameConstants.overlayGameOver,
      GameConstants.overlayRanking,
      GameConstants.overlaySettings,
      GameConstants.overlayCountdown,
      GameConstants.overlayReviveReady,
      GameConstants.overlayCollection,
    ];

    switch (state) {
      case GameState.mainMenu:
        _showOnly(allOverlays, GameConstants.overlayMainMenu);
        break;
      case GameState.playing:
        _showOnly(allOverlays, GameConstants.overlayHud);
        break;
      case GameState.paused:
        // Mantener HUD y añadir pausa
        _game.overlays.add(GameConstants.overlayPause);
        break;
      case GameState.victory:
        _showOnly(allOverlays, GameConstants.overlayVictory);
        break;
      case GameState.gameOver:
        _showOnly(allOverlays, GameConstants.overlayGameOver);
        break;
      case GameState.ranking:
        _showOnly(allOverlays, GameConstants.overlayRanking);
        break;
      case GameState.settings:
        _showOnly(allOverlays, GameConstants.overlaySettings);
        break;
      case GameState.countdown:
        _showOnly(allOverlays, GameConstants.overlayCountdown);
        break;
      case GameState.reviveReady:
        _showOnly(allOverlays, GameConstants.overlayReviveReady);
        break;
      case GameState.collection:
        _showOnly(allOverlays, GameConstants.overlayCollection);
        break;
    }
  }

  void _showOnly(List<String> all, String active) {
    for (final overlay in all) {
      if (overlay == active) {
        if (!_game.overlays.isActive(overlay)) {
          _game.overlays.add(overlay);
        }
      } else {
        _game.overlays.remove(overlay);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          final state = _game.gameManager.state;
          if (state == GameState.ranking || state == GameState.settings || state == GameState.collection) {
            _game.gameManager.goToMenu();
          } else if (state == GameState.playing) {
            _game.pauseGame();
            _game.gameManager.pauseGame();
          } else if (state == GameState.paused) {
            _game.resumeGame();
            _game.gameManager.resumeGame();
          } else if (state == GameState.mainMenu) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF16213E), // Color oscuro del tema en lugar de negro puro
        body: Column(
        children: [
          Expanded(
            child: GameWidget<BalloonHunterGame>.controlled(
              gameFactory: () => _game,
              loadingBuilder: (context) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF43E97B)),
                    const SizedBox(height: 16),
                    Text(
                      'Cargando...',
                      style: GoogleFonts.fredoka(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
              overlayBuilderMap: {
        // -- Menú principal --
        GameConstants.overlayMainMenu: (context, game) => MainMenuScreen(
              gameManager: game.gameManager,
              onNewGame: () async {
                await game.gameManager.startNewGame();
                game.startGame();
              },
              onResume: () async {
                await game.gameManager.continueSavedGame();
                game.startGame(); 
              },
              onRanking: () =>
                  game.gameManager.changeState(GameState.ranking),
              onSettings: () =>
                  game.gameManager.changeState(GameState.settings),
              onCollection: () =>
                  game.gameManager.changeState(GameState.collection),
            ),

        // -- Colección --
        GameConstants.overlayCollection: (context, game) => CollectionScreen(
              gameManager: game.gameManager,
              onBack: () => game.gameManager.goToMenu(),
            ),

        // -- HUD en juego --
        GameConstants.overlayHud: (context, game) => HudOverlay(
              gameManager: game.gameManager,
              onPause: () async {
                game.pauseGame();
                await game.gameManager.pauseGame();
              },
            ),

        // -- Pausa --
        GameConstants.overlayPause: (context, game) => PauseScreen(
              gameManager: game.gameManager,
              onResume: () async {
                game.resumeGame();
                await game.gameManager.resumeGame();
              },
              onMenu: () async {
                game.resumeGame();
                await game.gameManager.goToMenu();
                game.goToMenu();
              },
            ),

        // -- Victoria --
        GameConstants.overlayVictory: (context, game) => VictoryScreen(
              gameManager: game.gameManager,
              onNextLevel: () async {
                await game.gameManager.startNextLevel();
                game.startGame();
              },
              onMenu: () async {
                await game.gameManager.goToMenu();
                game.goToMenu();
              },
            ),

        // -- Game Over --
        GameConstants.overlayGameOver: (context, game) => GameOverScreen(
              gameManager: game.gameManager,
              birdHit: game.gameManager.state == GameState.gameOver,
              onPlayAgain: () async {
                await game.gameManager.startNewGame();
                game.startGame();
              },
              onRevive: () async {
                await game.gameManager.reviveLevel();
                game.startGame();
              },
              onMenu: () async {
                await game.gameManager.goToMenu();
                game.goToMenu();
              },
            ),

        // -- Ranking --
        GameConstants.overlayRanking: (context, game) => RankingScreen(
              gameManager: game.gameManager,
              onNewGame: () async {
                await game.gameManager.startNewGame();
                game.startGame();
              },
              onResume: () async {
                await game.gameManager.continueSavedGame();
                game.startGame();
              },
              onBack: () => game.gameManager.goToMenu(),
            ),

        // -- Ajustes --
        GameConstants.overlaySettings: (context, game) => SettingsScreen(
              gameManager: game.gameManager,
              onBack: () => game.gameManager.goToMenu(),
            ),

        // -- Countdown --
        GameConstants.overlayCountdown: (context, game) => CountdownScreen(
              gameManager: game.gameManager,
              onCountdownComplete: () {
                // El countdown finalizó, ahora sí iniciamos a jugar
                game.gameManager.changeState(GameState.playing);
              },
            ),

        // -- Revive Ready --
        GameConstants.overlayReviveReady: (context, game) => ReviveReadyScreen(
              gameManager: game.gameManager,
              onContinue: () {
                game.gameManager.startReviveCountdown();
              },
            ),
      },
              initialActiveOverlays: const [GameConstants.overlayMainMenu],
            ),
          ),
          // Banner Ad at the bottom
          const BannerAdWidget(),
        ],
      ),
    ));
  }
}

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AdManager().loadBannerAd(context);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AdManager(),
      builder: (context, child) {
        if (AdManager().isBannerAdLoaded && AdManager().bannerAd != null) {
          return Container(
            width: double.infinity,
            height: AdManager().bannerAd!.size.height.toDouble(),
            child: AdWidget(ad: AdManager().bannerAd!),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
