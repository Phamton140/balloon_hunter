// lib/screens/ranking_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:games_services/games_services.dart';
import '../managers/game_manager.dart';
import '../models/score_record.dart';
import '../screens/game_over_screen.dart'; // Added for _LevelSelectionDialog
import '../utils/palette.dart';
import '../utils/constants.dart';
import '../managers/save_manager.dart';

class RankingScreen extends StatelessWidget {
  final GameManager gameManager;
  final VoidCallback? onNewGame;
  final VoidCallback? onResume;
  final VoidCallback? onBack;

  const RankingScreen({
    super.key,
    required this.gameManager,
    this.onNewGame,
    this.onResume,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = gameManager.saveManager.currentTheme;

    return DefaultTabController(
      length: 4,
      child: Container(
        decoration: const BoxDecoration(
          gradient: Palette.menuGradient,
        ),
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

              // Tabs
              TabBar(
                indicatorColor: Palette.balloonBlue,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                labelStyle: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'Personal'),
                  Tab(text: 'Amigos'),
                  Tab(text: 'Nacional'),
                  Tab(text: 'Mundial'),
                ],
              ),

              const SizedBox(height: 10),

              // Tab Views
              Expanded(
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    gameManager.authManager,
                    gameManager.rankingManager,
                    gameManager.friendsManager,
                  ]),
                  builder: (context, _) {
                    final isLoggedIn = gameManager.authManager.isLoggedIn;
                    return TabBarView(
                      children: [
                        _buildPersonalRanking(),
                        _buildOnlineRanking(context, 'amigos'),
                        _buildOnlineRanking(context, 'nacional'),
                        _buildOnlineRanking(context, 'mundial'),
                      ],
                    );
                  },
                ),
              ),

              // Play Button
              Padding(
                padding: const EdgeInsets.all(20),
                child: GestureDetector(
                  onTap: () => _handlePlayTap(context),
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
      ),
    );
  }

  Widget _buildPersonalRanking() {
    final bestScoreCloud = gameManager.rankingManager.getBestScore();
    final rawRecordCloud = gameManager.rankingManager.getPersonalRecord();
    final rawRecordLocal = gameManager.saveManager.getPersonalRecord();
    
    final bestScoreLocal = (rawRecordLocal?['score'] as num?)?.toInt() ?? 0;
    
    // Usar el mejor registro entre la nube y el local
    Map<String, dynamic>? rawRecord;
    if (bestScoreCloud >= bestScoreLocal && rawRecordCloud != null) {
      rawRecord = rawRecordCloud;
    } else if (bestScoreLocal > bestScoreCloud && rawRecordLocal != null) {
      rawRecord = rawRecordLocal;
    } else {
      rawRecord = rawRecordCloud ?? rawRecordLocal;
    }

    final bestScore = (rawRecord?['score'] as num?)?.toInt() ?? 0;

    if (bestScore == 0 || rawRecord == null) {
      return Center(
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
      );
    }

    List<dynamic> scoresToDisplay = [];
    if (rawRecord.containsKey('topScores')) {
      scoresToDisplay = List.from(rawRecord['topScores'] as List);
    } else {
      scoresToDisplay = [rawRecord];
    }
    // Ordenar por puntuación de mayor a menor (los mejores al inicio)
    // Empate: quien lo haya logrado primero se coloca antes
    scoresToDisplay.sort((a, b) {
      final scoreA = a['score'] as num;
      final scoreB = b['score'] as num;
      if (scoreA > scoreB) return -1;
      if (scoreA < scoreB) return 1;
      return 0;
    });

    return Column(
      children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('👤', style: TextStyle(fontSize: 40)),
            const SizedBox(width: 10),
            Text('Récord Personal', style: GoogleFonts.fredoka(fontSize: 20, color: Colors.white)),
          ],
        ),
        const SizedBox(height: 20),
        _buildTableHeader(showCountry: false),
        Expanded(
          child: ListView.builder(
            itemCount: scoresToDisplay.length,
            itemBuilder: (context, i) {
              final scoreData = scoresToDisplay[i] as Map<String, dynamic>;
              final record = ScoreRecord.fromMap(scoreData);
              return _TableRow(
                record: record,
                position: i + 1,
                playerName: gameManager.authManager.isLoggedIn ? gameManager.authManager.playerName : 'Tú',
                isCurrentUser: false,
                isEven: i % 2 == 0,
              ).animate(delay: Duration(milliseconds: i * 50)).fadeIn().slideX(begin: -0.2);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOnlineRanking(BuildContext context, String type) {
    return _buildMockRanking(context, type);
  }

  Widget _buildMockRanking(BuildContext context, String type) {
    if (gameManager.rankingManager.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Palette.balloonBlue));
    }
    
    final globalScores = gameManager.rankingManager.globalScores;
    
    // Configurar Cabecera visual
    String headerEmoji = '🌎';
    String headerText = 'Ranking Mundial';
    if (type == 'nacional') {
      headerEmoji = _getFlagEmoji(gameManager.authManager.playerCountryCode);
      headerText = 'Ranking Nacional';
    } else if (type == 'amigos') {
      headerEmoji = '👥';
      headerText = 'Amigos';
    }

    List<Map<String, dynamic>> filteredScores = List.from(globalScores);
    
    if (type == 'nacional') {
      filteredScores = filteredScores.where((score) => score['countryCode'] == gameManager.authManager.playerCountryCode).toList();
    } else if (type == 'amigos') {
      final myFriends = gameManager.friendsManager.friendIds;
      filteredScores = filteredScores.where((score) => myFriends.contains(score['playerId']) || score['playerId'] == gameManager.authManager.playerId).toList();
    }
    
    if (filteredScores.isEmpty && type != 'amigos') {
        return Center(
          child: Text(
            '¡Sé el primero en conquistar este ranking!',
            textAlign: TextAlign.center,
            style: GoogleFonts.fredoka(fontSize: 18, color: Colors.white60),
          ),
        );
      }

    final items = <dynamic>[]; 
    final names = <String>[];
    final mockCodes = <String?>[];
    final positions = <int>[];
    
    for (int i = 0; i < filteredScores.length; i++) {
        final scoreData = filteredScores[i];
        final record = ScoreRecord.fromMap(scoreData);
        items.add(record);
        names.add(scoreData['playerName'] ?? 'Desconocido');
        mockCodes.add(scoreData['countryCode']);
        positions.add(i + 1);
    }

    return Column(
      children: [
        const SizedBox(height: 20),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: type == 'amigos' ? () => _showAddFriendCodeDialog(context) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: type == 'amigos'
                ? BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF43E97B).withValues(alpha: 0.3), width: 1.5),
                  )
                : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                type == 'amigos' 
                    ? Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Text(headerEmoji, style: const TextStyle(fontSize: 36)),
                          Positioned(
                            bottom: -2,
                            right: -6,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFF1A0A2E), // Fondo oscuro para contraste
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add_circle,
                                color: Color(0xFF43E97B),
                                size: 20,
                              ),
                            ).animate(onPlay: (c) => c.repeat(reverse: true))
                             .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.2, 1.2), duration: 800.ms),
                          ),
                        ],
                      )
                    : Text(headerEmoji, style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 10),
                Text(
                  type == 'amigos' ? 'Añadir Amigo / Ranking' : headerText,
                  style: GoogleFonts.fredoka(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildTableHeader(showCountry: true),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) {
              final isPlayer = filteredScores[i]['playerId'] == gameManager.authManager.playerId;
              return GestureDetector(
                onTap: () => _showPlayerOptions(context, filteredScores[i]),
                child: _TableRow(
                  record: items[i] as ScoreRecord,
                  position: positions[i],
                  playerName: names[i],
                  countryCode: mockCodes[i],
                  isCurrentUser: isPlayer,
                  isEven: i % 2 == 0,
                ).animate(delay: Duration(milliseconds: (i < 10 ? i : 0) * 50)).fadeIn().slideX(begin: -0.2),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFriendsHeader(BuildContext context) {
    return GestureDetector(
          onTap: () => _showAddFriendCodeDialog(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('👥', style: TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Text('Añadir Amigo', style: GoogleFonts.fredoka(fontSize: 18, color: Colors.white)),
                const SizedBox(width: 8),
                const Icon(Icons.add_circle, color: Color(0xFF43E97B), size: 24),
              ],
            ),
          ),
        );
  }

  void _showAddFriendCodeDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text('Añadir por Código', style: GoogleFonts.fredoka(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Ej. BHT-X7K9',
            hintStyle: TextStyle(color: Colors.white54),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.canPop(ctx) ? Navigator.pop(ctx) : null, child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () async {
              final success = await gameManager.friendsManager.addFriendByCode(controller.text);
              if (context.mounted) {
                if (Navigator.canPop(ctx)) Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Amigo añadido' : 'Código inválido o ya añadido')));
              }
            },
            child: const Text('Añadir'),
          ),
        ],
      ),
    );
  }

  void _showPlayerOptions(BuildContext context, Map<String, dynamic> playerData) {
    if (playerData['playerId'] == gameManager.authManager.playerId) return;

    final isFriend = gameManager.friendsManager.friendIds.contains(playerData['playerId']);
    final pendingRequest = gameManager.inboxManager.pendingRequests
        .where((r) => r.fromPlayerId == playerData['playerId'])
        .isNotEmpty;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(playerData['playerName'] ?? 'Jugador', style: GoogleFonts.fredoka(fontSize: 24, color: Colors.white)),
            const SizedBox(height: 20),
            // Botón principal depende del estado
            if (!isFriend && !pendingRequest)
              ListTile(
                leading: const Icon(Icons.person_add, color: Colors.white),
                title: const Text('Añadir Amigo', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  final success = await gameManager.friendsManager.addFriendById(playerData['playerId']);
                  if (context.mounted) {
                    if (Navigator.canPop(ctx)) Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Añadido a amigos' : 'No se pudo añadir')));
                  }
                },
              )
            else if (isFriend)
              ListTile(
                leading: const Icon(Icons.person_remove, color: Colors.white),
                title: const Text('Eliminar Amigo', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  final confirmed = await showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF2C2C2C),
                      title: Text('Eliminar Amigo', style: GoogleFonts.fredoka(color: Colors.white)),
                      content: Text('¿Estás seguro de eliminar a este amigo?', style: TextStyle(color: Colors.white70)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.canPop(ctx) ? Navigator.pop(ctx) : null,
                          child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                          onPressed: () {
                            if (Navigator.canPop(ctx)) Navigator.pop(ctx);
                            // Lógica para eliminar amigo (se haría en friends_manager)
                            if (Navigator.canPop(context)) Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Amigo eliminado')));
                          },
                          child: Text('Confirmar', style: GoogleFonts.fredoka(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  if (confirmed && context.mounted) {
                    // Aquí se llamaría a la eliminación real
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Funcionalidad de eliminación por implementar')));
                  }
                },
              )
            else if (pendingRequest)
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.white),
                title: const Text('Cancelar Invitación', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  final success = await gameManager.inboxManager.respondToRequest(
                    /* need to get request id */ '',
                    playerData['playerId'],
                    false
                  );
                  if (context.mounted) {
                    if (Navigator.canPop(ctx)) Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Invitación cancelada' : 'Error al cancelar')));
                  }
                },
              ),
          ],
        ),
      ),
    );
  }


  Widget _buildTableHeader({required bool showCountry}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black26,
      child: Row(
        children: [
          const SizedBox(width: 40, child: Text('#', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold))),
          Expanded(
            child: Text('JUGADOR', style: GoogleFonts.fredoka(color: Colors.white54, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 50, child: Text('NVL', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold))),
          const SizedBox(width: 80, child: Text('PTS', textAlign: TextAlign.right, style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  String _getFlagEmoji(String countryCode) {
    switch (countryCode.toUpperCase()) {
      case 'DO': return '🇩🇴';
      case 'US': return '🇺🇸';
      case 'JP': return '🇯🇵';
      case 'BR': return '🇧🇷';
      case 'MX': return '🇲🇽';
      case 'ES': return '🇪🇸';
      case 'FR': return '🇫🇷';
      case 'DE': return '🇩🇪';
      case 'IT': return '🇮🇹';
      default: return '🏳️';
    }
  }

  void _handlePlayTap(BuildContext context) {
    if (gameManager.hasSavedGame) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: Text(
            'Partida en progreso',
            style: GoogleFonts.fredoka(color: Colors.white),
          ),
          content: Text(
            '¿Desea continuar con la partida anterior?\n\nNivel: ${gameManager.saveManager.savedLevel}\nPuntuación: ${gameManager.saveManager.savedScore}',
            style: const TextStyle(color: Colors.white70),
          ),
actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  showDialog(
                    context: context,
                    barrierColor: Colors.black87,
                    builder: (context) => LevelSelectionDialog(
                      maxLevelReached: gameManager.saveManager.maxLevelReached,
onLevelSelected: (startLevel) {
            if (Navigator.canPop(context)) Navigator.of(context).pop();
            gameManager.startNewGame(startLevel: startLevel);
          },
                    ),
                  );
                },
                child: const Text('NUEVA PARTIDA', style: TextStyle(color: Colors.redAccent)),
              ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onResume?.call();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF43E97B)),
              child: const Text('CONTINUAR', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        barrierColor: Colors.black87,
builder: (context) => LevelSelectionDialog(
          maxLevelReached: gameManager.saveManager.maxLevelReached,
          onLevelSelected: (startLevel) {
            Navigator.of(context).pop();
            onNewGame?.call();
          },
        ),
      );
    }
  }
}

class _TableRow extends StatelessWidget {
  final ScoreRecord record;
  final int position;
  final String playerName;
  final bool isCurrentUser;
  final String? countryCode;
  final bool isEven;

  const _TableRow({
    required this.record,
    required this.position,
    required this.playerName,
    required this.isCurrentUser,
    this.countryCode,
    required this.isEven,
  });

  @override
  Widget build(BuildContext context) {
    final bool isTop3 = position <= 3;
    final medalEmojis = ['🥇', '🥈', '🥉'];
    final posText = isTop3 ? medalEmojis[position - 1] : '$position';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isCurrentUser 
            ? Palette.balloonBlue.withValues(alpha: 0.2) 
            : (isEven ? Colors.white.withValues(alpha: 0.05) : Colors.transparent),
        border: isCurrentUser 
            ? Border.symmetric(horizontal: BorderSide(color: Palette.balloonBlue.withValues(alpha: 0.8), width: 1.5))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40, 
            child: Text(
              posText, 
              style: TextStyle(
                fontSize: isTop3 ? 20 : 16, 
                color: isTop3 ? null : Colors.white70, 
                fontWeight: FontWeight.bold
              )
            )
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (countryCode != null) ...[
                      Text(_getFlagEmoji(countryCode!), style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        playerName,
                        style: GoogleFonts.fredoka(
                          fontSize: 16, 
                          color: isCurrentUser ? Colors.white : Colors.white70,
                          fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('🎯 ${record.accuracy.toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    const SizedBox(width: 8),
                    Text('💥 x${record.maxCombo}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    const SizedBox(width: 8),
                    Text('🎈 ${record.balloonsDestroyed}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            width: 50, 
            child: Text(
              '${record.level}', 
              style: GoogleFonts.fredoka(color: Colors.white70, fontSize: 14)
            )
          ),
          SizedBox(
            width: 80, 
            child: Text(
              '${record.score}', 
              textAlign: TextAlign.right,
              style: GoogleFonts.fredoka(
                color: isCurrentUser ? Palette.balloonBlueGlow : Colors.white, 
                fontWeight: FontWeight.bold,
                fontSize: 16
              )
            )
          ),
        ],
      ),
    );
  }

  String _getFlagEmoji(String countryCode) {
    switch (countryCode.toUpperCase()) {
      case 'DO': return '🇩🇴';
      case 'US': return '🇺🇸';
      case 'JP': return '🇯🇵';
      case 'BR': return '🇧🇷';
      case 'MX': return '🇲🇽';
      case 'ES': return '🇪🇸';
      case 'FR': return '🇫🇷';
      case 'DE': return '🇩🇪';
      case 'IT': return '🇮🇹';
      default: return '🏳️';
    }
  }
}
