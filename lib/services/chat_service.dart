import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message.dart';
import 'notification_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'local_storage_service.dart';
import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

// Result wrapper for better error handling
class ChatResult<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  ChatResult.success(this.data) : error = null, isSuccess = true;
  ChatResult.failure(this.error) : data = null, isSuccess = false;
}

// Configuration class for chat settings
class ChatConfig {
  static const String usersCollection = 'users';
  static const String chatsCollection = 'chats';
  static const String messagesSubCollection = 'messages';
  static const int messageLimit = 50;
  static const Duration typingTimeout = Duration(seconds: 3);
}

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  
  ChatService._internal() {
    _initializeService();
  }

  // Private fields
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();
  
  String? _cachedUserId;
  Map<String, Map<String, dynamic>> _userCache = {};
  Timer? _typingTimer;

  // Getters
  String? get currentUserId => _auth.currentUser?.uid ?? _cachedUserId;
  bool get isAuthenticated => _auth.currentUser != null;

  // Initialize service
  Future<void> _initializeService() async {
    try {
      _cachedUserId = await LocalStorageService.getUserId();
      print('ChatService initialized with user ID: $_cachedUserId');
    } catch (e) {
      print('Error initializing ChatService: $e');
    }
  }

  // Enhanced user management with caching
  Future<ChatResult<Map<String, dynamic>>> getUserById(String userId) async {
    try {
      // Check cache first
      if (_userCache.containsKey(userId)) {
        return ChatResult.success(_userCache[userId]!);
      }

      final doc = await _firestore
          .collection(ChatConfig.usersCollection)
          .doc(userId)
          .get();

      if (!doc.exists) {
        return ChatResult.failure('User not found');
      }

      final data = doc.data()!;
      final userData = {
        'id': doc.id,
        'firstName': data['firstName'] ?? '',
        'lastName': data['lastName'] ?? '',
        'fullName': '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim(),
        'email': data['email'] ?? '',
        'image': data['image'] ?? '',
        'role': data['role'] ?? 'user',
        'isOnline': data['isOnline'] ?? false,
        'lastSeen': data['lastSeen'],
      };

      // Cache the user data
      _userCache[userId] = userData;
      
      return ChatResult.success(userData);
    } catch (e) {
      return ChatResult.failure('Error fetching user: $e');
    }
  }

  // Improved user listing with pagination
  Stream<ChatResult<List<Map<String, dynamic>>>> getAllUsers({
    int limit = 20,
    String? lastUserId,
  }) {
    try {
      if (!isAuthenticated) {
        return Stream.value(ChatResult.failure('User not authenticated'));
      }

      Query query = _firestore
          .collection(ChatConfig.usersCollection)
          .where('id', isNotEqualTo: currentUserId)
          .orderBy('id')
          .limit(limit);

      if (lastUserId != null) {
        query = query.startAfter([lastUserId]);
      }

      return query.snapshots().map((snapshot) {
        try {
          final users = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final userData = {
              'id': doc.id,
              'firstName': data['firstName'] ?? '',
              'lastName': data['lastName'] ?? '',
              'fullName': '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim(),
              'email': data['email'] ?? '',
              'image': data['image'] ?? '',
              'role': data['role'] ?? 'user',
              'isOnline': data['isOnline'] ?? false,
              'lastSeen': data['lastSeen'],
            };
            
            // Cache user data
            _userCache[doc.id] = userData;
            return userData;
          }).toList();

          return ChatResult.success(users);
        } catch (e) {
          return ChatResult.failure('Error processing users: $e');
        }
      });
    } catch (e) {
      return Stream.value(ChatResult.failure('Error getting users: $e'));
    }
  }

  // Enhanced chat channel management
  String getChatChannelId(String userId1, String userId2) {
    if (userId1.isEmpty || userId2.isEmpty) {
      throw ArgumentError('User IDs cannot be empty');
    }
    
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  Future<ChatResult<void>> ensureChatChannel(String otherUserId) async {
    try {
      if (!isAuthenticated) {
        return ChatResult.failure('User not authenticated');
      }

      if (otherUserId.isEmpty) {
        return ChatResult.failure('Invalid user ID');
      }

      final channelId = getChatChannelId(currentUserId!, otherUserId);
      
      // Check if chat channel exists
      final chatDoc = await _firestore
          .collection(ChatConfig.chatsCollection)
          .doc(channelId)
          .get();
      
      if (chatDoc.exists) {
        return ChatResult.success(null);
      }

      // Get user details for both users
      final currentUserResult = await getUserById(currentUserId!);
      final otherUserResult = await getUserById(otherUserId);

      if (!currentUserResult.isSuccess || !otherUserResult.isSuccess) {
        return ChatResult.failure('Failed to get user data');
      }

      final currentUserData = currentUserResult.data!;
      final otherUserData = otherUserResult.data!;

      // Create new chat channel with enhanced metadata
      await _firestore
          .collection(ChatConfig.chatsCollection)
          .doc(channelId)
          .set({
        'participants': [currentUserId, otherUserId],
        'participantData': {
          currentUserId!: {
            'name': currentUserData['fullName'],
            'image': currentUserData['image'],
            'role': currentUserData['role'],
          },
          otherUserId: {
            'name': otherUserData['fullName'], 
            'image': otherUserData['image'],
            'role': otherUserData['role'],
          },
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': currentUserId,
        'messageCount': 0,
        'unreadCount': {
          currentUserId!: 0,
          otherUserId: 0,
        },
        'isActive': true,
      });

      return ChatResult.success(null);
    } catch (e) {
      return ChatResult.failure('Error creating chat channel: $e');
    }
  }

  // Enhanced message sending with better error handling
  Future<ChatResult<String>> sendMessage({
    required String receiverId,
    required String content,
    String type = 'text',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (!isAuthenticated) {
        return ChatResult.failure('User not authenticated');
      }

      if (content.trim().isEmpty) {
        return ChatResult.failure('Message content cannot be empty');
      }

      // Ensure chat channel exists
      final channelResult = await ensureChatChannel(receiverId);
      if (!channelResult.isSuccess) {
        return ChatResult.failure(channelResult.error!);
      }

      final channelId = getChatChannelId(currentUserId!, receiverId);
      print('Sending message in channel: $channelId');
      print('From: $currentUserId');
      print('To: $receiverId');
      print('Content: $content');

      final messageRef = _firestore
          .collection(ChatConfig.chatsCollection)
          .doc(channelId)
          .collection(ChatConfig.messagesSubCollection)
          .doc();

      final now = DateTime.now();
      final message = Message(
        id: messageRef.id,
        senderId: currentUserId!,
        receiverId: receiverId,
        content: content.trim(),
        timestamp: now,
        isRead: false,
      );

      // Use transaction for consistency
      await _firestore.runTransaction((transaction) async {
        // Add message
        transaction.set(messageRef, message.toMap());

        // Update chat channel
        final chatRef = _firestore
            .collection(ChatConfig.chatsCollection)
            .doc(channelId);
        
        transaction.update(chatRef, {
          'lastMessage': content.trim(),
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastMessageSender': currentUserId,
          'updatedAt': FieldValue.serverTimestamp(),
          'messageCount': FieldValue.increment(1),
          'unreadCount.$receiverId': FieldValue.increment(1),
        });
      });

      print('Message sent successfully');
      return ChatResult.success(messageRef.id);
    } catch (e) {
      print('Error sending message: $e');
      return ChatResult.failure('Error sending message: $e');
    }
  }

  // Enhanced message retrieval with pagination and filtering
  Stream<List<Message>> getMessages(
    String otherUserId, {
    int limit = ChatConfig.messageLimit,
    DocumentSnapshot? lastMessageDocument,
  }) {
    try {
      if (!isAuthenticated || currentUserId == null) {
        return Stream.value([]); // Return empty list if not authenticated
      }

      final channelId = getChatChannelId(currentUserId!, otherUserId);
      print('Getting messages for channel: $channelId');
      print('Current user: $currentUserId');
      print('Other user: $otherUserId');

      // Create query with proper filtering
      Query query = _firestore
          .collection(ChatConfig.chatsCollection)
          .doc(channelId)
          .collection(ChatConfig.messagesSubCollection)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (lastMessageDocument != null) {
        query = query.startAfterDocument(lastMessageDocument);
      }

      return query.snapshots().map((snapshot) {
        try {
          final messages = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            print('Raw message data: $data');
            
            // Ensure sender and receiver IDs are properly set
            final senderId = data['senderId']?.toString() ?? '';
            final receiverId = data['receiverId']?.toString() ?? '';
            
            print('Message from $senderId to $receiverId');
            print('Content: ${data['content']}');
            
            // Create message with proper sender/receiver
            return Message.fromMap({
              ...data,
              'id': doc.id,
              'senderId': senderId,
              'receiverId': receiverId,
            });
          }).toList();

          // Sort messages by timestamp in ascending order for display
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          
          print('Processed ${messages.length} messages');
          return messages;
        } catch (e) {
          print('Error processing messages: $e');
          return []; // Return empty list on error
        }
      });
    } catch (e) {
      print('Error getting messages: $e');
      return Stream.value([]); // Return empty list on error
    }
  }

  // Enhanced chat channels with better data structure
  Stream<ChatResult<List<ChatChannel>>> getChatChannels() {
    try {
      if (!isAuthenticated) {
        return Stream.value(ChatResult.failure('User not authenticated'));
      }

      return _firestore
          .collection(ChatConfig.chatsCollection)
          .where('participants', arrayContains: currentUserId)
          .where('isActive', isEqualTo: true)
          .orderBy('lastMessageTime', descending: true)
          .snapshots()
          .map((snapshot) {
        try {
          final channels = snapshot.docs.map((doc) {
            final data = doc.data();
            final participants = List<String>.from(data['participants'] ?? []);
            final otherUserId = participants.firstWhere(
              (id) => id != currentUserId,
              orElse: () => '',
            );

            return ChatChannel(
              id: doc.id,
              otherUserId: otherUserId,
              otherUserData: data['participantData']?[otherUserId] ?? {},
              lastMessage: data['lastMessage'] ?? '',
              lastMessageTime: data['lastMessageTime'] as Timestamp?,
              lastMessageSender: data['lastMessageSender'] ?? '',
              unreadCount: data['unreadCount']?[currentUserId] ?? 0,
              messageCount: data['messageCount'] ?? 0,
              isActive: data['isActive'] ?? true,
            );
          }).toList();

          return ChatResult.success(channels);
        } catch (e) {
          return ChatResult.failure('Error processing chat channels: $e');
        }
      });
    } catch (e) {
      return Stream.value(ChatResult.failure('Error getting chat channels: $e'));
    }
  }

  // Helper method to mark messages as read
  Future<void> markMessagesAsRead(String otherUserId) async {
    try {
      if (!isAuthenticated || currentUserId == null) return;

      final channelId = getChatChannelId(currentUserId!, otherUserId);
      
      // Get unread messages
      final unreadMessages = await _firestore
          .collection(ChatConfig.chatsCollection)
          .doc(channelId)
          .collection(ChatConfig.messagesSubCollection)
          .where('senderId', isEqualTo: otherUserId)
          .where('receiverId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      // Mark messages as read in a batch
      final batch = _firestore.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      // Update unread count in chat channel
      await _firestore
          .collection(ChatConfig.chatsCollection)
          .doc(channelId)
          .update({
        'unreadCount.$currentUserId': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Enhanced typing indicators with auto-cleanup
  Future<ChatResult<void>> setTypingStatus(String otherUserId, bool isTyping) async {
    try {
      if (!isAuthenticated) {
        return ChatResult.failure('User not authenticated');
      }

      final channelId = getChatChannelId(currentUserId!, otherUserId);

      await _firestore
          .collection(ChatConfig.chatsCollection)
          .doc(channelId)
          .update({
        'typing.${currentUserId!}': isTyping ? FieldValue.serverTimestamp() : FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Auto-cleanup typing status after timeout
      if (isTyping) {
        _typingTimer?.cancel();
        _typingTimer = Timer(ChatConfig.typingTimeout, () {
          setTypingStatus(otherUserId, false);
        });
      }

      return ChatResult.success(null);
    } catch (e) {
      return ChatResult.failure('Error setting typing status: $e');
    }
  }

  Stream<bool> getTypingStatus(String otherUserId) {
    try {
      if (!isAuthenticated) {
        return Stream.value(false);
      }

      final channelId = getChatChannelId(currentUserId!, otherUserId);

      return _firestore
          .collection(ChatConfig.chatsCollection)
          .doc(channelId)
          .snapshots()
          .map((doc) {
        final typingData = doc.data()?['typing'] as Map<String, dynamic>?;
        if (typingData == null || !typingData.containsKey(otherUserId)) {
          return false;
        }

        final typingTimestamp = typingData[otherUserId] as Timestamp?;
        if (typingTimestamp == null) return false;

        // Check if typing status is still valid (within timeout)
        final now = DateTime.now();
        final typingTime = typingTimestamp.toDate();
        return now.difference(typingTime) < ChatConfig.typingTimeout;
      });
    } catch (e) {
      print('Error getting typing status: $e');
      return Stream.value(false);
    }
  }

  // Enhanced push notification
  Future<void> _sendPushNotification(String receiverId, String message) async {
    try {
      final receiverResult = await getUserById(receiverId);
      if (!receiverResult.isSuccess) return;

      final receiverData = receiverResult.data!;
      final fcmToken = receiverData['fcmToken'];

      if (fcmToken != null) {
        final currentUserResult = await getUserById(currentUserId!);
        final senderName = currentUserResult.data?['fullName'] ?? 'Someone';

        await _notificationService.sendNotification(
          token: fcmToken,
          title: 'New message from $senderName',
          body: message.length > 100 ? '${message.substring(0, 100)}...' : message,
          data: {
            'type': 'message',
            'senderId': currentUserId!,
            'channelId': getChatChannelId(currentUserId!, receiverId),
          },
        );
      }
    } catch (e) {
      print('Error sending push notification: $e');
    }
  }

  // Enhanced cleanup
  Future<ChatResult<void>> deleteChatRoom(String otherUserId) async {
    try {
      if (!isAuthenticated) {
        return ChatResult.failure('User not authenticated');
      }

      final channelId = getChatChannelId(currentUserId!, otherUserId);
      
      await _firestore.runTransaction((transaction) async {
        // Get all messages
        final messagesSnapshot = await _firestore
            .collection(ChatConfig.chatsCollection)
            .doc(channelId)
            .collection(ChatConfig.messagesSubCollection)
            .get();

        // Delete all messages
        for (var doc in messagesSnapshot.docs) {
          transaction.delete(doc.reference);
        }

        // Mark chat room as inactive instead of deleting
        final chatRef = _firestore
            .collection(ChatConfig.chatsCollection)
            .doc(channelId);
        
        transaction.update(chatRef, {
          'isActive': false,
          'deletedAt': FieldValue.serverTimestamp(),
          'deletedBy': currentUserId,
        });
      });

      return ChatResult.success(null);
    } catch (e) {
      return ChatResult.failure('Error deleting chat room: $e');
    }
  }

  // API integration with better error handling
  Future<ChatResult<List<Map<String, dynamic>>>> fetchAllUsersFromApi() async {
    try {
      final response = await http.get(
        Uri.parse('https://careconnect-api-v2kw.onrender.com/api/user/all'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> users = json.decode(response.body);
        final userList = users.map((user) => user as Map<String, dynamic>).toList();
        
        // Cache the users
        for (var user in userList) {
          if (user['id'] != null) {
            _userCache[user['id']] = user;
          }
        }
        
        return ChatResult.success(userList);
      } else {
        return ChatResult.failure('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      return ChatResult.failure('Error fetching users from API: $e');
    }
  }

  // Cleanup method
  void dispose() {
    _typingTimer?.cancel();
    _userCache.clear();
  }
}

// Data model for chat channels
class ChatChannel {
  final String id;
  final String otherUserId;
  final Map<String, dynamic> otherUserData;
  final String lastMessage;
  final Timestamp? lastMessageTime;
  final String lastMessageSender;
  final int unreadCount;
  final int messageCount;
  final bool isActive;

  ChatChannel({
    required this.id,
    required this.otherUserId,
    required this.otherUserData,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.lastMessageSender,
    required this.unreadCount,
    required this.messageCount,
    required this.isActive,
  });
}