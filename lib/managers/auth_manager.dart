import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'save_manager.dart';

/// Gestiona la sesión del jugador usando Firebase, Google y Facebook.
class AuthManager extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
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

  /// Inicia sesión con Google
  Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false; // El usuario canceló

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      return true;
    } catch (e) {
      debugPrint('[AuthManager] Error en signInWithGoogle: $e');
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
