import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'auth_manager.dart';

import 'inbox_manager.dart';

class FriendsManager extends ChangeNotifier {
  final AuthManager _authManager;
  final InboxManager _inboxManager;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<String> _friendIds = [];
  String? _myFriendCode;
  bool _isLoading = false;

  FriendsManager(this._authManager, this._inboxManager) {
    _authManager.addListener(_onAuthChanged);
  }

  List<String> get friendIds => _friendIds;
  String get myFriendCode => _myFriendCode ?? '...';
  bool get isLoading => _isLoading;

  void _onAuthChanged() {
    if (_authManager.isLoggedIn) {
      _initializeUserDoc();
    } else {
      _friendIds = [];
      _myFriendCode = null;
      notifyListeners();
    }
  }

  Future<void> _initializeUserDoc() async {
    try {
      final uid = _authManager.playerId;
      debugPrint('[FIRESTORE] [Profile] Intentando leer perfil del jugador ($uid)...');
      final docRef = _firestore.collection('users').doc(uid);
      final doc = await docRef.get();

      if (!doc.exists) {
        debugPrint('[FIRESTORE] [Profile] Documento no existe. Creando nuevo perfil...');
        _myFriendCode = _generateRandomCode();
        await docRef.set({
          'friendCode': _myFriendCode,
          'friendsList': [],
          'facebookId': _authManager.facebookId,
        });
        _friendIds = [];
        debugPrint('[FIRESTORE] [Profile] Escritura: SUCCESS | FriendCode generado: $_myFriendCode');
      } else {
        debugPrint('[FIRESTORE] [Profile] Lectura: SUCCESS | Documento encontrado');
        final data = doc.data()!;
        _myFriendCode = data['friendCode'] ?? _generateRandomCode();
        if (data['friendCode'] == null) {
          await docRef.update({'friendCode': _myFriendCode});
        }
        if (data['facebookId'] != _authManager.facebookId && _authManager.facebookId != null) {
          await docRef.update({'facebookId': _authManager.facebookId});
        }
        
        _friendIds = List<String>.from(data['friendsList'] ?? []);
        debugPrint('[FIRESTORE] [Profile] FriendCode activo: $_myFriendCode | Amigos: ${_friendIds.length}');
      }
    } catch (e) {
      debugPrint('[FIRESTORE] [Profile] Error leyendo/escribiendo perfil: $e');
      if (_myFriendCode == null) _myFriendCode = _generateRandomCode();
    }
    notifyListeners();
  }

  String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return 'BHT-${List.generate(4, (index) => chars[random.nextInt(chars.length)]).join()}';
  }

  /// Añadir a alguien por su ID de Jugador (Tap en la tabla de ranking) envía solicitud
  Future<bool> addFriendById(String targetPlayerId) async {
    if (!_authManager.isLoggedIn || targetPlayerId == _authManager.playerId) return false;
    if (_friendIds.contains(targetPlayerId)) return true; // Ya lo sigue

    _isLoading = true;
    notifyListeners();

    try {
      final success = await _inboxManager.sendRequest(targetPlayerId);
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      debugPrint('[FriendsManager] Error sending friend request: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Añadir a alguien por su Código de Amigo (BHT-XXXX)
  Future<bool> addFriendByCode(String code) async {
    if (!_authManager.isLoggedIn) return false;
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode == _myFriendCode) return false; // No te puedes añadir a ti mismo

    _isLoading = true;
    notifyListeners();

    try {
      // Buscar el usuario con ese código
      final query = await _firestore
          .collection('users')
          .where('friendCode', isEqualTo: cleanCode)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final targetPlayerId = query.docs.first.id;
      return await addFriendById(targetPlayerId);
    } catch (e) {
      debugPrint('[FriendsManager] Error adding friend by code: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Buscar amigos en Facebook y añadirlos si juegan Balloon Hunter
  Future<int> syncFacebookFriends() async {
    if (!_authManager.isLoggedIn || _authManager.facebookId == null) return 0;
    
    _isLoading = true;
    notifyListeners();
    
    int newFriendsAdded = 0;
    try {
      // Pedimos a la Graph API la lista de amigos que usan la app
      final userData = await FacebookAuth.instance.getUserData(fields: "friends");
      if (userData.containsKey('friends') && userData['friends']['data'] != null) {
        final friendsData = userData['friends']['data'] as List;
        final fbIds = friendsData.map((e) => e['id'].toString()).toList();
        
        if (fbIds.isNotEmpty) {
           // Buscar en Firestore los usuarios que tengan estos facebookIds
           final query = await _firestore.collection('users')
              .where('facebookId', whereIn: fbIds)
              .get();
              
           final newIds = <String>[];
           for (var doc in query.docs) {
             if (!_friendIds.contains(doc.id)) {
                newIds.add(doc.id);
             }
           }
           
           if (newIds.isNotEmpty) {
             _friendIds.addAll(newIds);
             await _firestore.collection('users').doc(_authManager.playerId).update({
                'friendsList': FieldValue.arrayUnion(newIds)
             });
             newFriendsAdded = newIds.length;
           }
        }
      }
    } catch (e) {
      debugPrint('[FriendsManager] Error syncing Facebook friends: $e');
    }
    
    _isLoading = false;
    notifyListeners();
    return newFriendsAdded;
  }
}
