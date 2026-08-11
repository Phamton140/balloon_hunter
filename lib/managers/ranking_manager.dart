import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:games_services/games_services.dart';
import '../models/score_record.dart';
import '../utils/constants.dart';
import 'auth_manager.dart';

class RankingManager extends ChangeNotifier {
  final AuthManager _authManager;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<Map<String, dynamic>> _globalScores = [];
  Map<String, dynamic>? _personalBestRecord;
  bool _isLoading = false;

  RankingManager(this._authManager);

  List<Map<String, dynamic>> get globalScores => _globalScores;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    // Activar persistencia offline de Firestore
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: 104857600, // Límite de 100 MB para evitar saturar el teléfono
    );
    
    // Iniciar sesión silenciosa en Google Play Games
    try {
      await GamesServices.signIn();
    } catch (e) {
      debugPrint('[RankingManager] Error auto-signin Play Games: $e');
    }
  }

  /// Sincroniza el récord más alto de Play Games con el progreso local y Firebase
  Future<void> syncPlayGamesScore(dynamic saveManager) async {
    try {
      if (await GamesServices.isSignedIn) {
        final dynamic pScore = await GamesServices.getPlayerScore(
          androidLeaderboardID: GameConstants.leaderboardGlobalId,
        );
        
        int playGamesScore = 0;
        if (pScore is int) {
          playGamesScore = pScore;
        } else if (pScore != null) {
          try {
            playGamesScore = pScore.value ?? 0;
          } catch (_) {}
        }
        
        if (playGamesScore > 0) {
          final localBest = getBestScore();
          if (playGamesScore > localBest) {
            debugPrint('[RankingManager] Restaurando récord desde Play Games: $playGamesScore');
            
            final newRecord = ScoreRecord(
              score: playGamesScore, 
              date: DateTime.now(),
              level: 1,
              balloonsDestroyed: 0,
              accuracy: 0.0,
              maxCombo: 0,
            );
            await addRecord(newRecord);
            
            final currentSavedScore = saveManager.savedScore;
            if (playGamesScore > currentSavedScore) {
              await saveManager.saveGame(level: 1, score: playGamesScore);
              await saveManager.clearSave(); 
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[RankingManager] Error sync Play Games: $e');
    }
  }

  /// Descarga el Top 100 mundial desde Firestore
  Future<void> fetchGlobalRanking() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Intentar obtener datos de la caché primero para rapidez, luego del servidor
      final snapshot = await _firestore
          .collection('leaderboard')
          .orderBy('score', descending: true)
          .orderBy('date', descending: false)
          .limit(100)
          .get(const GetOptions(source: Source.serverAndCache));

      _globalScores = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Fetch personal record specifically since it might not be in the top 100
      if (_authManager.isLoggedIn) {
        final myDoc = await _firestore.collection('leaderboard').doc(_authManager.playerId).get(const GetOptions(source: Source.serverAndCache));
        if (myDoc.exists) {
          _personalBestRecord = myDoc.data();
          _personalBestRecord?['id'] = myDoc.id;
        }
      }
    } catch (e) {
      debugPrint('[RankingManager] Error fetching global ranking: $e');
      // Intento offline puro si falla el servidor
      try {
        final snapshot = await _firestore
            .collection('leaderboard')
            .orderBy('score', descending: true)
            .orderBy('date', descending: false)
            .limit(100)
            .get(const GetOptions(source: Source.cache));
            
        _globalScores = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();

        // Fetch personal record specifically from cache
        if (_authManager.isLoggedIn) {
          try {
            final myDoc = await _firestore.collection('leaderboard').doc(_authManager.playerId).get(const GetOptions(source: Source.cache));
            if (myDoc.exists) {
              _personalBestRecord = myDoc.data();
              _personalBestRecord?['id'] = myDoc.id;
            }
          } catch (_) {}
        }
      } catch (e2) {
         debugPrint('[RankingManager] Fallback cache error: $e2');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Retorna la mejor puntuación local (buscando en los globales si existe el ID)
  int getBestScore() {
    if (!_authManager.isLoggedIn) return 0;
    
    // Primero intentamos con el récord personal consultado directamente
    if (_personalBestRecord != null) {
      return (_personalBestRecord!['score'] as num?)?.toInt() ?? 0;
    }
    
    // Fallback: buscar en los globales
    try {
      final myRecord = _globalScores.firstWhere(
        (record) => record['playerId'] == _authManager.playerId,
      );
      return (myRecord['score'] as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Retorna el registro personal completo si existe
  Map<String, dynamic>? getPersonalRecord() {
    if (_personalBestRecord != null) return _personalBestRecord;
    try {
      return _globalScores.firstWhere(
        (record) => record['playerId'] == _authManager.playerId,
      );
    } catch (_) {
      return null;
    }
  }

  /// Agrega un nuevo registro
  Future<bool> addRecord(ScoreRecord record) async {
    // Si no está logueado, podríamos guardar localmente o simplemente ignorar
    if (!_authManager.isLoggedIn) return false;

    try {
      // 1. Guardar en Firestore
      final docRef = _firestore.collection('leaderboard').doc(_authManager.playerId);
      
      bool isNewRecord = true;
      try {
        final doc = await docRef.get(const GetOptions(source: Source.serverAndCache));
        if (doc.exists) {
          final currentScore = doc.data()?['score'] ?? 0;
          if (record.score <= currentScore) {
            isNewRecord = false; // No superó su propio récord
          }
        }
      } catch (e) {
        // Si falla la lectura (ej. sin internet y sin caché), asumimos que es récord nuevo
        // para asegurar que al menos se intente guardar localmente en la caché.
      }

      if (isNewRecord) {
        final data = record.toMap();
        data['playerName'] = _authManager.playerName;
        data['countryCode'] = _authManager.playerCountryCode;
        data['playerId'] = _authManager.playerId;
        
        // No hacer await para no bloquear el juego si no hay internet
        docRef.set(data, SetOptions(merge: true));
        
        // Actualizar la memoria instantáneamente de forma "radical"
        _personalBestRecord = data;
        _personalBestRecord!['id'] = _authManager.playerId;
        // 2. Enviar a Google Play Games en segundo plano
        try {
          if (await GamesServices.isSignedIn) {
            await GamesServices.submitScore(
              score: Score(
                androidLeaderboardID: GameConstants.leaderboardGlobalId,
                value: record.score,
              ),
            );
          }
        } catch (e) {
          debugPrint('[RankingManager] Play Games submit error: $e');
        }
        
        // Refrescar ranking
        await fetchGlobalRanking();
      }
      return isNewRecord;
    } catch (e) {
      debugPrint('[RankingManager] Error adding record: $e');
      return false;
    }
  }
}
