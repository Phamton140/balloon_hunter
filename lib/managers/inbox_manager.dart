import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_manager.dart';

class FriendRequest {
  final String id;
  final String fromPlayerId;
  final String fromPlayerName;
  final String status;
  final DateTime createdAt;

  FriendRequest({
    required this.id,
    required this.fromPlayerId,
    required this.fromPlayerName,
    required this.status,
    required this.createdAt,
  });

  factory FriendRequest.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FriendRequest(
      id: doc.id,
      fromPlayerId: data['fromPlayerId'] ?? '',
      fromPlayerName: data['fromPlayerName'] ?? 'Desconocido',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class InboxManager extends ChangeNotifier {
  final AuthManager _authManager;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<FriendRequest> _pendingRequests = [];
  bool _isLoading = false;

  InboxManager(this._authManager) {
    _authManager.addListener(_onAuthChanged);
  }

  List<FriendRequest> get pendingRequests => _pendingRequests;
  bool get isLoading => _isLoading;
  bool get hasUnread => _pendingRequests.isNotEmpty;

  void _onAuthChanged() {
    if (_authManager.isLoggedIn) {
      _fetchRequests();
    } else {
      _pendingRequests = [];
      notifyListeners();
    }
  }

  Future<void> _fetchRequests() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_authManager.playerId)
          .collection('friend_requests')
          .where('status', isEqualTo: 'pending')
          .get();

      _pendingRequests = snapshot.docs.map((doc) => FriendRequest.fromDocument(doc)).toList();
    } catch (e) {
      debugPrint('[InboxManager] Error fetching requests: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendRequest(String targetPlayerId) async {
    if (!_authManager.isLoggedIn || targetPlayerId == _authManager.playerId) return false;
    try {
      await _firestore
          .collection('users')
          .doc(targetPlayerId)
          .collection('friend_requests')
          .doc(_authManager.playerId)
          .set({
        'fromPlayerId': _authManager.playerId,
        'fromPlayerName': _authManager.playerName,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('[InboxManager] Error sending request: $e');
      return false;
    }
  }

  Future<bool> respondToRequest(String requestId, String fromPlayerId, bool accept) async {
    if (!_authManager.isLoggedIn) return false;
    try {
      await _firestore
          .collection('users')
          .doc(_authManager.playerId)
          .collection('friend_requests')
          .doc(requestId)
          .update({'status': accept ? 'accepted' : 'rejected'});

      if (accept) {
        await _firestore.collection('users').doc(_authManager.playerId).update({
          'friendsList': FieldValue.arrayUnion([fromPlayerId])
        });
        await _firestore.collection('users').doc(fromPlayerId).update({
          'friendsList': FieldValue.arrayUnion([_authManager.playerId])
        });
      }

      _pendingRequests.removeWhere((r) => r.id == requestId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[InboxManager] Error responding to request: $e');
      return false;
    }
  }
}
