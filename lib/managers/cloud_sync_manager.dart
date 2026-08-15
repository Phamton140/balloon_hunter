// lib/managers/cloud_sync_manager.dart
// Sincroniza el progreso del jugador con Firebase Firestore

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class CloudSyncManager {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '925661441666-0scd36q759oaq4hlq1a6t8v44hug3a8t.apps.googleusercontent.com',
  );

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
      debugPrint('[AUTH] Inicializando CloudSyncManager...');
      _currentUser = _auth.currentUser;
      
      if (_currentUser == null) {
        debugPrint('[AUTH] Iniciando Firebase Auth anónimo...');
        UserCredential userCredential = await _auth.signInAnonymously();
        _currentUser = userCredential.user;
        debugPrint('[AUTH] Firebase signIn Anónimo resultado: SUCCESS | UID: ${_currentUser?.uid}');
      } else {
        debugPrint('[AUTH] Firebase sesión existente detectada | UID: ${_currentUser?.uid} | GoogleLinked: $isGoogleLinked');
      }
      
      _isInitialized = true;
      debugPrint('[AUTH] Estado final CloudSyncManager: ${_currentUser != null ? "CONNECTED" : "DISCONNECTED"} | UID: ${_currentUser?.uid}');
    } catch (e) {
      debugPrint('[AUTH] Firebase Auth error en initialize: $e');
    }
  }

  /// Vincula la cuenta anónima actual con Google para no perder el progreso,
  /// o inicia sesión si ya tenía una cuenta creada.
  Future<bool> linkGoogleAccount() async {
    try {
      debugPrint('[AUTH] Iniciando flujo Google Sign-In para vincular...');
      GoogleSignInAccount? googleUser;
      try {
        googleUser = await _googleSignIn.signIn();
      } catch (e) {
        debugPrint('[AUTH] Google Sign-In error al abrir ventana: $e');
        return false;
      }
      if (googleUser == null) {
        debugPrint('[AUTH] Google Sign-In cancelado por el usuario.');
        return false;
      }

      debugPrint('[AUTH] Google Sign-In cuenta seleccionada: ${googleUser.email} (ID: ${googleUser.id})');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      debugPrint('[AUTH] Google Tokens obtenidos: idToken=${googleAuth.idToken != null ? "PRESENTE (${googleAuth.idToken!.substring(0, 15)}...)" : "NULL"}, accessToken=${googleAuth.accessToken != null ? "PRESENTE" : "NULL"}');

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      debugPrint('[AUTH] Firebase credential creada: YES');

      // Si el usuario ya está anónimo, intentamos vincularle la credencial de Google
      if (_currentUser != null && _currentUser!.isAnonymous) {
        try {
          debugPrint('[AUTH] Intentando linkWithCredential en usuario anónimo (${_currentUser!.uid})...');
          final linkResult = await _currentUser!.linkWithCredential(credential);
          _currentUser = linkResult.user;
          debugPrint('[AUTH] Firebase linkWithCredential resultado: SUCCESS | UID: ${_currentUser?.uid}');
          debugPrint('[AUTH] Estado final: CONNECTED (Google Linked)');
          return true;
        } on FirebaseAuthException catch (e) {
          debugPrint('[AUTH] FirebaseAuthException en linkWithCredential: ${e.code} - ${e.message}');
          if (e.code == 'credential-already-in-use') {
            debugPrint('[AUTH] La credencial ya existe en otro usuario. Iniciando sesión directamente...');
            final userCredential = await _auth.signInWithCredential(credential);
            _currentUser = userCredential.user;
            debugPrint('[AUTH] Firebase signInWithCredential resultado: SUCCESS | UID: ${_currentUser?.uid}');
            debugPrint('[AUTH] Estado final: CONNECTED (Google Linked)');
            return true;
          }
        }
      } else {
        debugPrint('[AUTH] Iniciando sesión directa con credencial Google...');
        final userCredential = await _auth.signInWithCredential(credential);
        _currentUser = userCredential.user;
        debugPrint('[AUTH] Firebase signInWithCredential resultado: SUCCESS | UID: ${_currentUser?.uid}');
        debugPrint('[AUTH] Estado final: CONNECTED (Google Linked)');
        return true;
      }
    } catch (e) {
      debugPrint('[AUTH] Error vinculando Google: $e');
    }
    debugPrint('[AUTH] Estado final: FAIL / DISCONNECTED');
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
