// lib/managers/cloud_sync_manager.dart
// Sincroniza el progreso del jugador con Firebase Firestore

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class CloudSyncManager {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? _currentUser;
  User? get currentUser => _currentUser;
  
  bool _isInitialized = false;

  /// Retorna si el usuario actual ha vinculado su cuenta de Google
  bool get isGoogleLinked {
    if (_currentUser == null) return false;
    return _currentUser!.providerData.any((info) => info.providerId == 'google.com');
  }

  /// Inicia sesión de forma anónima y prepara la base de datos
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      // Intentar recuperar sesión actual
      _currentUser = _auth.currentUser;
      
      // Si no hay sesión en absoluto, iniciar anónimamente por defecto
      if (_currentUser == null) {
        UserCredential userCredential = await _auth.signInAnonymously();
        _currentUser = userCredential.user;
      }
      
      _isInitialized = true;
      debugPrint('[CloudSyncManager] Auth exitoso. UID: ${_currentUser?.uid}, Google: $isGoogleLinked');
    } catch (e) {
      debugPrint('[CloudSyncManager] Error de autenticación: $e');
    }
  }

  /// Vincula la cuenta anónima actual con Google para no perder el progreso,
  /// o inicia sesión si ya tenía una cuenta creada.
  Future<bool> linkGoogleAccount() async {
    try {
      GoogleSignInAccount? googleUser;
      try {
        googleUser = await _googleSignIn.signIn();
      } catch (e) {
        debugPrint('[CloudSyncManager] Google Sign-In cancelado o fallido: $e');
        return false;
      }
      if (googleUser == null) return false;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Si el usuario ya está anónimo, intentamos vincularle la credencial de Google
      if (_currentUser != null && _currentUser!.isAnonymous) {
        try {
          await _currentUser!.linkWithCredential(credential);
          debugPrint('[CloudSyncManager] Cuenta vinculada con éxito.');
          return true;
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use') {
            // Si la cuenta de Google ya tenía progreso guardado de otra instalación,
            // iniciamos sesión directamente (se descarta el progreso anónimo actual en favor de la nube)
            debugPrint('[CloudSyncManager] La cuenta ya existe. Iniciando sesión directamente...');
            final userCredential = await _auth.signInWithCredential(credential);
            _currentUser = userCredential.user;
            return true;
          }
        }
      } else {
        // Si por alguna razón no había usuario, simplemente iniciamos sesión
        final userCredential = await _auth.signInWithCredential(credential);
        _currentUser = userCredential.user;
        return true;
      }
    } catch (e) {
      debugPrint('[CloudSyncManager] Error vinculando Google: $e');
    }
    return false;
  }

  /// Cierra la sesión de Google
  Future<void> signOutGoogle() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    _currentUser = null;
    _isInitialized = false;
    await initialize(); // Vuelve a crear una cuenta anónima limpia
  }

  /// Sube a la nube el nivel máximo alcanzado si es superior al guardado
  Future<void> syncMaxLevel(int newMaxLevel) async {
    if (!_isInitialized || _currentUser == null) return;
    try {
      final docRef = _firestore.collection('users').doc(_currentUser!.uid);
      
      // Obtener datos actuales de la nube
      final snapshot = await docRef.get();
      int cloudMaxLevel = 0;
      if (snapshot.exists) {
        cloudMaxLevel = snapshot.data()?['maxLevel'] ?? 0;
      }

      // Solo actualizar si el nivel local es estrictamente mayor que el de la nube
      if (newMaxLevel > cloudMaxLevel) {
        await docRef.set({
          'maxLevel': newMaxLevel,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('[CloudSyncManager] Nivel máximo sincronizado a Firestore: $newMaxLevel (UID: ${_currentUser!.uid})');
      }
    } catch (e) {
      debugPrint('[CloudSyncManager] Error sincronizando nivel: $e');
    }
  }

  /// Descarga el nivel máximo desde la nube (ideal para cuando se instala el juego en un nuevo dispositivo)
  Future<int?> fetchMaxLevel() async {
    if (!_isInitialized || _currentUser == null) return null;
    try {
      final docRef = _firestore.collection('users').doc(_currentUser!.uid);
      final snapshot = await docRef.get();
      if (snapshot.exists) {
        return snapshot.data()?['maxLevel'] as int?;
      }
    } catch (e) {
      debugPrint('[CloudSyncManager] Error descargando nivel: $e');
    }
    return null;
  }
}
