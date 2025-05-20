import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message.dart';
import 'notification_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'local_storage_service.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  
  late String? chatUserId;
  
  ChatService._internal() {
    _initializeUserRole();
  }

  Future<void> _initializeUserRole() async {
    chatUserId = await LocalStorageService.getUserId();
    print('User role from storage: $chatUserId');
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  String? get currentUserId => _auth.currentUser?.uid;

  // Get all users in the system
  Stream<List<Map<String, dynamic>>> getAllUsers() {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      return _firestore
          .collection('users')
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'firstName': data['firstName'] ?? '',
            'lastName': data['lastName'] ?? '',
            'email': data['email'] ?? '',
            'image': data['image'] ?? '',
            'role': data['role'] ?? 'user',
          };
        }).toList();
      });
    } catch (e) {
      print('Error getting users: $e');
      rethrow;
    }
  }

  // Get user details by ID
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      return {
        'id': doc.id,
        'firstName': data['firstName'] ?? '',
        'lastName': data['lastName'] ?? '',
        'email': data['email'] ?? '',
        'image': data['image'] ?? '',
        'role': data['role'] ?? 'user',
      };
    } catch (e) {
      print('Error getting user: $e');
      rethrow;
    }
  }

  // Generate a unique chat channel ID for two users
  String getChatChannelId(String userId1, String userId2) {
    // Sort the IDs to ensure consistent channel ID regardless of who initiates
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  // Ensure chat channel exists
  Future<void> ensureChatChannel(String otherUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final channelId = getChatChannelId(currentUser.uid, otherUserId);
      
      // Check if chat channel exists
      final chatDoc = await _firestore.collection('chats').doc(channelId).get();
      
      if (!chatDoc.exists) {
        // Get user details for both users
        final currentUserData = await getUserById(currentUser.uid);
        final otherUserData = await getUserById(otherUserId);

        if (currentUserData == null || otherUserData == null) {
          throw Exception('User data not found');
        }

        // Create new chat channel
        await _firestore.collection('chats').doc(channelId).set({
          'participants': [currentUser.uid, otherUserId],
          'participantNames': {
            currentUser.uid: '${currentUserData['firstName']} ${currentUserData['lastName']}',
            otherUserId: '${otherUserData['firstName']} ${otherUserData['lastName']}',
          },
          'participantImages': {
            currentUser.uid: currentUserData['image'],
            otherUserId: otherUserData['image'],
          },
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastMessageSender': currentUser.uid,
          'lastMessageReceiver': otherUserId,
        });
      }
    } catch (e) {
      print('Error ensuring chat channel: $e');
      rethrow;
    }
  }

  // Send a message
  Future<void> sendMessage({
    required String receiverId,
    required String content,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Ensure chat channel exists
      await ensureChatChannel(receiverId);

      final channelId = getChatChannelId(currentUser.uid, receiverId);
      final messageId = _firestore.collection('chats').doc(channelId).collection('messages').doc().id;

      final message = Message(
        id: messageId,
        senderId: currentUser.uid,
        receiverId: receiverId,
        content: content,
        timestamp: DateTime.now(),
        isRead: false,
      );

      // Add message to messages collection
      await _firestore
          .collection('chats')
          .doc(channelId)
          .collection('messages')
          .doc(messageId)
          .set(message.toMap());

      // Update last message in chat document
      await _firestore.collection('chats').doc(channelId).set({
        'lastMessage': content,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'participants': [currentUser.uid, receiverId],
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessageSender': currentUser.uid,
        'lastMessageReceiver': receiverId,
      }, SetOptions(merge: true));

      // Send push notification
      await _sendPushNotification(receiverId, content);
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Get messages for a chat channel
  Stream<List<Message>> getMessages(String otherUserId) {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final channelId = getChatChannelId(currentUser.uid, otherUserId);

      return _firestore
          .collection('chats')
          .doc(channelId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          return Message(
            id: doc.id,
            senderId: data['senderId'] ?? '',
            receiverId: data['receiverId'] ?? '',
            content: data['content'] ?? '',
            timestamp: (data['timestamp'] as Timestamp).toDate(),
            isRead: data['isRead'] ?? false,
          );
        }).toList();
      });
    } catch (e) {
      print('Error getting messages: $e');
      rethrow;
    }
  }

  // Get all chat channels for current user
  Stream<List<Map<String, dynamic>>> getChatChannels() {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      return _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUser.uid)
          .orderBy('lastMessageTime', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          final participants = List<String>.from(data['participants'] ?? []);
          final otherUserId = participants.firstWhere((id) => id != currentUser.uid);
          
          return {
            'channelId': doc.id,
            'otherUserId': otherUserId,
            'lastMessage': data['lastMessage'] ?? '',
            'lastMessageTime': data['lastMessageTime'],
            'lastMessageSender': data['lastMessageSender'],
            'lastMessageReceiver': data['lastMessageReceiver'],
          };
        }).toList();
      });
    } catch (e) {
      print('Error getting chat channels: $e');
      rethrow;
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String otherUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final channelId = getChatChannelId(currentUser.uid, otherUserId);
      
      // Get all unread messages
      final unreadMessages = await _firestore
          .collection('chats')
          .doc(channelId)
          .collection('messages')
          .where('receiverId', isEqualTo: currentUser.uid)
          .where('isRead', isEqualTo: false)
          .get();

      // Mark each message as read
      final batch = _firestore.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking messages as read: $e');
      rethrow;
    }
  }

  // Get typing status
  Stream<bool> getTypingStatus(String otherUserId) {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final channelId = getChatChannelId(currentUser.uid, otherUserId);

      return _firestore
          .collection('chats')
          .doc(channelId)
          .snapshots()
          .map((doc) => doc.data()?['typing'] == otherUserId);
    } catch (e) {
      print('Error getting typing status: $e');
      rethrow;
    }
  }

  // Set typing status
  Future<void> setTypingStatus(String otherUserId, bool isTyping) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final channelId = getChatChannelId(currentUser.uid, otherUserId);

      await _firestore.collection('chats').doc(channelId).set({
        'typing': isTyping ? currentUser.uid : null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error setting typing status: $e');
      rethrow;
    }
  }

  // Send push notification
  Future<void> _sendPushNotification(String receiverId, String message) async {
    try {
      // Get receiver's FCM token
      final receiverDoc = await _firestore.collection('users').doc(receiverId).get();
      final fcmToken = receiverDoc.data()?['fcmToken'];

      if (fcmToken != null) {
        final currentUser = _auth.currentUser;
        if (currentUser == null) return;

        // Get sender's name
        final senderDoc = await _firestore.collection('users').doc(currentUser.uid).get();
        final senderName = senderDoc.data()?['name'] ?? 'Someone';

        await _notificationService.sendNotification(
          token: fcmToken,
          title: 'New message from $senderName',
          body: message,
          data: {
            'type': 'message',
            'senderId': currentUser.uid,
            'channelId': getChatChannelId(currentUser.uid, receiverId),
          },
        );
      }
    } catch (e) {
      print('Error sending push notification: $e');
    }
  }

  // Delete chat room and all its messages
  Future<void> deleteChatRoom(String otherUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final channelId = getChatChannelId(currentUser.uid, otherUserId);
      
      // Get all messages in the chat room
      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(channelId)
          .collection('messages')
          .get();

      // Delete all messages in a batch
      final batch = _firestore.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete the chat room document
      batch.delete(_firestore.collection('chats').doc(channelId));

      // Commit the batch
      await batch.commit();
    } catch (e) {
      print('Error deleting chat room: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllUsersFromApi() async {
    final response = await http.get(
      Uri.parse('https://careconnect-api-v2kw.onrender.com/api/user/all'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> users = json.decode(response.body);
      return users.map((user) => user as Map<String, dynamic>).toList();
    } else {
      throw Exception('Failed to load users');
    }
  }
} 