import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FirebaseMessagingService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Initialize Firebase Messaging
  Future<void> initialize() async {
    // Request permission for notifications
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token
    String? token = await _messaging.getToken();
    if (token != null) {
      await _updateUserToken(token);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      _updateUserToken(newToken);
    });
  }

  // Update user's FCM token in Firestore
  Future<void> _updateUserToken(String token) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': token,
      });
    }
  }

  // Create or get chat room
  Future<String> getOrCreateChatRoom(String doctorId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Create a unique chat room ID by combining user IDs
    final chatRoomId = user.uid.compareTo(doctorId) < 0
        ? '${user.uid}_$doctorId'
        : '${doctorId}_${user.uid}';

    // Check if chat room exists
    final chatRoomRef = _firestore.collection('chatRooms').doc(chatRoomId);
    final chatRoom = await chatRoomRef.get();

    if (!chatRoom.exists) {
      // Create new chat room
      await chatRoomRef.set({
        'participants': [user.uid, doctorId],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    }

    return chatRoomId;
  }

  // Send message
  Future<void> sendMessage(String chatRoomId, String message) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final messageRef = _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages');

    await messageRef.add({
      'senderId': user.uid,
      'text': message,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update last message in chat room
    await _firestore.collection('chatRooms').doc(chatRoomId).update({
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  // Stream messages for a chat room
  Stream<QuerySnapshot> getMessages(String chatRoomId) {
    return _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Get user details
  Future<Map<String, dynamic>> getUserDetails(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    return userDoc.data() ?? {};
  }
} 