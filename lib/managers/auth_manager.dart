import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'save_manager.dart';

/// Gestiona la sesión del jugador usando Firebase, Google y Facebook.
class AuthManager extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '925661441666-0scd36q759oaq4hlq1a6t8v44hug3a8t.apps.googleusercontent.com',
  );
  SaveManager? _saveManager;
  
  bool _isLoggedIn = false;
  String? _playerName;
  String? _playerCountryCode;
  String? _playerId;
  String? _facebookId;
  
  bool get isLoggedIn => _auth.currentUser != null;
  String get playerName => _playerName ?? "Jugador";
  String get playerCountryCode => _playerCountryCode ?? "US";
  String get playerId => _auth.currentUser?.uid ?? "unknown";
  String? get facebookId => _facebookId;

  Future<void> initialize(SaveManager saveManager) async {
    _saveManager = saveManager;
    
    // Cargar desde SaveManager o detectar
    _playerName = saveManager.playerName ?? "Jugador";
    _playerCountryCode = saveManager.playerCountryCode;
    
    if (_playerCountryCode == null) {
      _playerCountryCode = "DO";
      // Guardar el detectado
      await saveManager.saveProfile(name: _playerName!, countryCode: _playerCountryCode!);
    }

    _auth.authStateChanges().listen((User? user) {
      debugPrint('[AUTH] AuthStateChanged disparado | User: ${user?.uid} | isAnonymous: ${user?.isAnonymous}');
      if (user != null) {
        _isLoggedIn = true;
        _playerId = user.uid;
        // Si el usuario tiene un displayName, lo podríamos usar, pero preferimos el del SaveManager
        if (saveManager.playerName == null && user.displayName != null && user.displayName!.isNotEmpty) {
           _playerName = user.displayName;
           saveManager.saveProfile(name: _playerName!, countryCode: _playerCountryCode!);
        }
      } else {
        _isLoggedIn = false;
        _playerId = null;
      }
      notifyListeners();
    });
  }

  /// Actualizar el perfil del jugador
  Future<void> updateProfile(String name, String countryCode) async {
    final cleanName = name.trim();
    _playerName = cleanName.length > 13 ? cleanName.substring(0, 13) : cleanName;
    _playerCountryCode = countryCode;
    await _saveManager?.saveProfile(name: name, countryCode: countryCode);
    notifyListeners();
  }

  /// Actualiza la última vez que el jugador estuvo activo para el sistema de auto-eliminación
  Future<void> updateLastActive() async {
    if (!isLoggedIn) return;
    try {
      final nameLower = (playerName ?? '').toLowerCase();
      final isProtected = nameLower == 'melquisedec' || nameLower.startsWith('19_96_');
      
      final Map<String, dynamic> updateData = {
        'lastActive': FieldValue.serverTimestamp(),
      };

      if (!isProtected) {
        final expireDate = DateTime.now().add(const Duration(days: 60));
        updateData['expireAt'] = Timestamp.fromDate(expireDate);
      } else {
        // Para usuarios protegidos, ponemos una fecha de expiración en 100 años (o simplemente la quitamos)
        final expireDate = DateTime.now().add(const Duration(days: 36500));
        updateData['expireAt'] = Timestamp.fromDate(expireDate);
      }

      await FirebaseAuth.instance.currentUser?.reload(); // Verifica validez de sesión
      await FirebaseFirestore.instance.collection('users').doc(playerId).set(updateData, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[AuthManager] Error updating lastActive: $e');
    }
  }

  /// Inicia sesión con Google
  Future<bool> signInWithGoogle() async {
    try {
      debugPrint('[AUTH] [AuthManager] Iniciando signInWithGoogle...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('[AUTH] [AuthManager] Google Sign-In cancelado por usuario');
        return false;
      }

      debugPrint('[AUTH] [AuthManager] Cuenta Google seleccionada: ${googleUser.email}');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      debugPrint('[AUTH] [AuthManager] Tokens: idToken=${googleAuth.idToken != null ? "OK" : "NULL"}, accessToken=${googleAuth.accessToken != null ? "OK" : "NULL"}');

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      debugPrint('[AUTH] [AuthManager] Credential creada: YES');

      final userCredential = await _auth.signInWithCredential(credential);
      debugPrint('[AUTH] [AuthManager] Firebase signIn resultado: SUCCESS | UID: ${userCredential.user?.uid}');
      return true;
    } catch (e) {
      debugPrint('[AUTH] [AuthManager] Error en signInWithGoogle: $e');
      return false;
    }
  }

  /// Inicia sesión con Facebook
  Future<bool> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status == LoginStatus.success) {
        final OAuthCredential credential = FacebookAuthProvider.credential(result.accessToken!.tokenString);
        await _auth.signInWithCredential(credential);
        
        // Obtenemos el ID de Facebook de los datos del usuario
        final userData = await FacebookAuth.instance.getUserData();
        _facebookId = userData['id'].toString();
        
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[AuthManager] Error en signInWithFacebook: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    await FacebookAuth.instance.logOut();
    _isLoggedIn = false;
    _playerName = null;
    _playerId = null;
    _facebookId = null;
    notifyListeners();
  }
}
