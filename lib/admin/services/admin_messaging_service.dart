import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

class AdminMessagingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Initialize messaging for admin
  Future<void> initialize() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    String? token = await _messaging.getToken();
    if (token != null) {
      await _updateAdminToken(token);
    }

    _messaging.onTokenRefresh.listen((newToken) {
      _updateAdminToken(newToken);
    });
  }

  // Update admin's FCM token
  Future<void> _updateAdminToken(String token) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('admins').doc(user.uid).update({
        'fcmToken': token,
      });
    }
  }

  // Get all chat rooms for admin
  Stream<QuerySnapshot> getAdminChatRooms() {
    final admin = _auth.currentUser;
    if (admin == null) throw Exception('Admin not authenticated');

    return _firestore
        .collection('chatRooms')
        .where('adminId', isEqualTo: admin.uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // Get unread message count for admin
  Stream<int> getUnreadMessageCount() {
    return _firestore
        .collection('chatRooms')
        .where('participants', arrayContains: _auth.currentUser?.uid)
        .snapshots()
        .map((snapshot) {
      int count = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['lastMessageSender'] != _auth.currentUser?.uid &&
            data['lastMessageTime'] != null) {
          final lastMessageTime = (data['lastMessageTime'] as Timestamp).toDate();
          final now = DateTime.now();
          if (now.difference(lastMessageTime).inMinutes < 5) {
            count++;
          }
        }
      }
      return count;
    });
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatRoomId) async {
    await _firestore.collection('chatRooms').doc(chatRoomId).update({
      'lastReadByAdmin': FieldValue.serverTimestamp(),
    });
  }

  // Get user details for a chat
  Future<Map<String, dynamic>> getChatUserDetails(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    return userDoc.data() ?? {};
  }

  // Helper function to extract user ID from JWT token
  String? extractUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final data = json.decode(decoded);
      
      return data['userId'] as String?;
    } catch (e) {
      print('Error parsing JWT token: $e');
      return null;
    }
  }

  Future<String> getOrCreateChatRoom(String userIdOrToken) async {
    final admin = _auth.currentUser;
    if (admin == null) throw Exception('Admin not authenticated');

    print('Original userIdOrToken: $userIdOrToken');

    // Extract actual user ID if a token was provided
    String actualUserId = userIdOrToken;
    if (userIdOrToken.contains('.')) { // Check if it's a JWT token
      final extractedId = extractUserIdFromToken(userIdOrToken);
      if (extractedId != null) {
        actualUserId = extractedId;
        print('Extracted user ID from token: $actualUserId');
      } else {
        print('Failed to extract user ID from token');
        throw Exception('Invalid user ID or token');
      }
    }

    print('Using user ID: $actualUserId');
    print('Admin ID: ${admin.uid}');

    // Get admin details
    final adminDoc = await _firestore.collection('admins').doc(admin.uid).get();
    if (!adminDoc.exists) {
      throw Exception('Admin document not found');
    }
    final adminData = adminDoc.data()!;
    final adminName = adminData['name'] ?? 'Admin';

    if (adminName.isEmpty) {
      throw Exception('Admin name is required');
    }

    // Get user details
    final userDoc = await _firestore.collection('users').doc(actualUserId).get();
    if (!userDoc.exists) {
      throw Exception('User document not found');
    }
    final userData = userDoc.data()!;
    final userName = userData['name'] ?? 'User';

    if (userName.isEmpty) {
      throw Exception('User name is required');
    }

    // Create a unique chat room ID
    final chatRoomId = '${admin.uid}_$actualUserId';
    print('Generated chat room ID: $chatRoomId');

    try {
      // Create new chat room
      final chatRoomRef = _firestore.collection('chatRooms').doc(chatRoomId);
      
      // Set initial chat room data
      await chatRoomRef.set({
        'participants': [admin.uid, actualUserId],
        'participantNames': [adminName, userName],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': admin.uid,
        'lastMessageSenderName': adminName,
        'adminId': admin.uid,
        'adminName': adminName,
        'userId': actualUserId,
        'userName': userName,
        'type': 'admin_user',
        'status': 'active',
        'unreadCount': 0,
      });

      print('Chat room created successfully');
      return chatRoomId;
    } catch (e) {
      print('Error creating chat room: $e');
      throw Exception('Failed to create chat room: $e');
    }
  }

  // Send a sample message for testing
  Future<void> sendSampleMessage(String chatRoomId) async {
    final sampleMessages = [
      "Hello! How can I help you today?",
      "Welcome to our support chat. I'm here to assist you.",
      "Thank you for reaching out. What can I do for you?",
      "I'm your support representative. How may I assist you?",
      "Good day! How can I make your experience better today?"
    ];

    final randomMessage = sampleMessages[DateTime.now().millisecondsSinceEpoch % sampleMessages.length];
    await sendMessage(chatRoomId, randomMessage);
  }

  // Send message as admin
  Future<void> sendMessage(String chatRoomId, String message) async {
    if (message.trim().isEmpty) {
      throw Exception('Message cannot be empty');
    }

    final user = _auth.currentUser;
    if (user == null) throw Exception('Admin not authenticated');

    print('Sending message in chat room: $chatRoomId');
    print('Message content: $message');
    print('Current user: ${user.uid}');

    // Get chat room details first
    final chatRoomDoc = await _firestore.collection('chatRooms').doc(chatRoomId).get();
    if (!chatRoomDoc.exists) {
      throw Exception('Chat room not found');
    }

    final chatRoomData = chatRoomDoc.data()!;
    final targetUserId = chatRoomData['userId'];
    final targetUserName = chatRoomData['userName'];

    if (targetUserId == null || targetUserName == null) {
      throw Exception('Invalid chat room data: missing user information');
    }

    // Get admin details
    final adminDoc = await _firestore.collection('admins').doc(user.uid).get();
    if (!adminDoc.exists) {
      throw Exception('Admin document not found');
    }
    final adminData = adminDoc.data()!;
    final adminName = adminData['name'] ?? 'Admin';

    // Validate all required data
    if (adminName.isEmpty) {
      throw Exception('Admin name is required');
    }

    // Create message data with enhanced information
    final messageData = {
      'senderId': user.uid,
      'senderName': adminName,
      'receiverId': targetUserId,
      'receiverName': targetUserName,
      'text': message.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'isAdmin': true,
      'type': 'text',
      'status': 'sent',
      'chatRoomId': chatRoomId,
    };

    // Validate message data
    if (messageData.values.any((value) => value == null)) {
      print('Message data validation failed: $messageData');
      throw Exception('Invalid message data: null values detected');
    }

    print('Message data to be stored: $messageData');

    try {
      // Add message to messages subcollection
      final messageRef = _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages');
      
      final messageDoc = await messageRef.add(messageData);
      print('Message added to Firestore with ID: ${messageDoc.id}');

      // Update chat room with last message
      final updateData = {
        'lastMessage': message.trim(),
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': user.uid,
        'lastMessageSenderName': adminName,
        'status': 'active',
        'unreadCount': FieldValue.increment(1),
      };

      await _firestore.collection('chatRooms').doc(chatRoomId).update(updateData);
      print('Chat room updated successfully');

      // Send notification to the user
      final userDoc = await _firestore.collection('users').doc(targetUserId).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final fcmToken = userData['fcmToken'];
        if (fcmToken != null) {
          await _sendFCMNotification(
            token: fcmToken,
            title: adminName,
            body: message.trim(),
            chatRoomId: chatRoomId,
          );
        }
      }
    } catch (e) {
      print('Error in message sending process: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  Future<void> _sendFCMNotification({
    required String token,
    required String title,
    required String body,
    required String chatRoomId,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'token': token,
        'title': title,
        'body': body,
        'chatRoomId': chatRoomId,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'chat_message',
      });
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  // Get messages for a chat room with enhanced error handling
  Stream<QuerySnapshot> getMessages(String chatRoomId) {
    print('Getting messages for chat room: $chatRoomId');
    return _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .handleError((error) {
          print('Error in messages stream: $error');
          throw error;
        });
  }

  // Add method to get chat room details
  Future<Map<String, dynamic>?> getChatRoomDetails(String chatRoomId) async {
    final doc = await _firestore.collection('chatRooms').doc(chatRoomId).get();
    return doc.data();
  }
} 