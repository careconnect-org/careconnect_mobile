import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_api_availability/google_api_availability.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> doctor;

  const ChatScreen({super.key, required this.doctor});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> messages = [];
  bool isLoading = true;
  String error = '';
  Stream<QuerySnapshot>? _messagesStream;
  String? _chatRoomId;
  String? _authToken;
  String? _editingMessageId;
  bool _isEditing = false;

  Future<void> _getStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('auth_token');
      print('Retrieved stored token: ${_authToken != null ? 'Token exists' : 'No token found'}');
    } catch (e) {
      print('Error getting stored token: $e');
    }
  }

  Future<void> _storeToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      _authToken = token;
      print('Token stored successfully');
    } catch (e) {
      print('Error storing token: $e');
    }
  }

  Future<void> _checkGooglePlayServices() async {
    try {
      final status = await GoogleApiAvailability.instance.checkGooglePlayServicesAvailability();
      if (status != GooglePlayServicesAvailability.success) {
        throw Exception('Google Play Services is not available: $status');
      }
    } catch (e) {
      print('Google Play Services check failed: $e');
      throw Exception('Please install or update Google Play Services');
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        // Try to get stored token
        await _getStoredToken();
        if (_authToken == null) {
          setState(() {
            error = 'Please login to view messages';
            isLoading = false;
          });
          return;
        }
      } else {
        // Get new token and store it
        final token = await user.getIdToken();
        if (token != null) {
          await _storeToken(token);
        } else {
          setState(() {
            error = 'Failed to get authentication token';
            isLoading = false;
          });
          return;
        }
      }

      // Ensure we have either a token or user ID
      final String identifier = _authToken ?? user?.uid ?? '';
      if (identifier.isEmpty) {
        setState(() {
          error = 'No valid user identifier found';
          isLoading = false;
        });
        return;
      }

      // Create chat room ID using stored token or user ID
      _chatRoomId = '${widget.doctor['id']}_$identifier';
      print('Chat room ID: $_chatRoomId');

      // Set up real-time listener for messages with proper ordering and persistence
      _messagesStream = _firestore
          .collection('chatRooms')
          .doc(_chatRoomId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots();

      // Create chat room if it doesn't exist
      final chatRoomDoc = await _firestore.collection('chatRooms').doc(_chatRoomId).get();
      if (!chatRoomDoc.exists) {
        print('Creating new chat room...');
        await _firestore.collection('chatRooms').doc(_chatRoomId).set({
          'participants': [identifier, widget.doctor['id']],
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastMessageSender': identifier,
          'lastMessageSenderName': user?.displayName ?? 'User',
          'status': 'active',
          'unreadCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('Chat room created successfully');
      } else {
        // Update last seen timestamp and ensure chat room is active
        await _firestore.collection('chatRooms').doc(_chatRoomId).update({
          'updatedAt': FieldValue.serverTimestamp(),
          'status': 'active',
        });
      }

      setState(() {
        isLoading = false;
        error = '';
      });
    } catch (e) {
      print('Error initializing chat: $e');
      setState(() {
        error = 'Failed to connect to chat: $e';
        isLoading = false;
      });
    }
  }

  Future<void> sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    String messageText = _messageController.text.trim();
    try {
      final user = _auth.currentUser;
      if (user == null && _authToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to send messages'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_chatRoomId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chat room not initialized'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      _messageController.clear(); // Clear the input field immediately

      // Get user details
      String userName = 'User';
      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        userName = userDoc.exists ? (userDoc.data()?['name'] ?? user.displayName ?? 'User') : (user.displayName ?? 'User');
      }

      final timestamp = FieldValue.serverTimestamp();
      final message = {
        'text': messageText,
        'senderId': user?.uid ?? _authToken,
        'senderName': userName,
        'timestamp': timestamp,
        'isAdmin': false,
        'type': 'text',
        'status': 'sent',
        'createdAt': timestamp,
        'updatedAt': timestamp,
      };

      print('Sending message: $message');

      // Add message to messages collection
      final messageRef = await _firestore
          .collection('chatRooms')
          .doc(_chatRoomId)
          .collection('messages')
          .add(message);

      // Update chat room with last message
      await _firestore.collection('chatRooms').doc(_chatRoomId).update({
        'lastMessage': messageText,
        'lastMessageTime': timestamp,
        'lastMessageSender': user?.uid ?? _authToken,
        'lastMessageSenderName': userName,
        'status': 'active',
        'unreadCount': FieldValue.increment(1),
        'updatedAt': timestamp,
      });

      print('Message sent successfully with ID: ${messageRef.id}');
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: Colors.red,
        ),
      );
      // Restore the message text if sending failed
      _messageController.text = messageText;
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      if (_chatRoomId == null) return;

      final timestamp = FieldValue.serverTimestamp();

      // Delete the message
      await _firestore
          .collection('chatRooms')
          .doc(_chatRoomId)
          .collection('messages')
          .doc(messageId)
          .delete();

      // Update last message if needed
      final messagesSnapshot = await _firestore
          .collection('chatRooms')
          .doc(_chatRoomId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (messagesSnapshot.docs.isNotEmpty) {
        final lastMessage = messagesSnapshot.docs.first.data();
        await _firestore.collection('chatRooms').doc(_chatRoomId).update({
          'lastMessage': lastMessage['text'],
          'lastMessageTime': lastMessage['timestamp'],
          'lastMessageSender': lastMessage['senderId'],
          'lastMessageSenderName': lastMessage['senderName'],
          'updatedAt': timestamp,
        });
      } else {
        // If no messages left, clear the last message
        await _firestore.collection('chatRooms').doc(_chatRoomId).update({
          'lastMessage': '',
          'lastMessageTime': timestamp,
          'lastMessageSender': null,
          'lastMessageSenderName': null,
          'updatedAt': timestamp,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message deleted'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error deleting message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _startEditing(String messageId, String currentText) async {
    setState(() {
      _editingMessageId = messageId;
      _isEditing = true;
      _messageController.text = currentText;
    });
  }

  Future<void> _updateMessage() async {
    if (_messageController.text.trim().isEmpty || _editingMessageId == null || _chatRoomId == null) return;

    try {
      final messageText = _messageController.text.trim();
      final timestamp = FieldValue.serverTimestamp();
      
      // Update the message
      await _firestore
          .collection('chatRooms')
          .doc(_chatRoomId)
          .collection('messages')
          .doc(_editingMessageId)
          .update({
        'text': messageText,
        'isEdited': true,
        'editedAt': timestamp,
        'updatedAt': timestamp,
      });

      // Update last message if this was the last message
      final messageDoc = await _firestore
          .collection('chatRooms')
          .doc(_chatRoomId)
          .collection('messages')
          .doc(_editingMessageId)
          .get();

      if (messageDoc.exists) {
        final messageData = messageDoc.data()!;
        final lastMessageDoc = await _firestore
            .collection('chatRooms')
            .doc(_chatRoomId)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        if (lastMessageDoc.docs.isNotEmpty && lastMessageDoc.docs.first.id == _editingMessageId) {
          await _firestore.collection('chatRooms').doc(_chatRoomId).update({
            'lastMessage': messageText,
            'updatedAt': timestamp,
          });
        }
      }

      setState(() {
        _editingMessageId = null;
        _isEditing = false;
        _messageController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message updated'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error updating message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _cancelEditing() {
    setState(() {
      _editingMessageId = null;
      _isEditing = false;
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Hero(
              tag: 'doctor_${widget.doctor['id']}',
              child: CircleAvatar(
                backgroundImage: NetworkImage(widget.doctor['image'] ?? ''),
                radius: 20,
                child: widget.doctor['image'] == null
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.doctor['name'] ?? 'Unknown Doctor',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  StreamBuilder<DocumentSnapshot>(
                    stream: _firestore.collection('chatRooms').doc(_chatRoomId).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        final data = snapshot.data!.data() as Map<String, dynamic>?;
                        if (data != null && data['status'] == 'active') {
                          return const Text(
                            'Online',
                            style: TextStyle(fontSize: 12, color: Colors.green),
                          );
                        }
                      }
                      return const Text(
                        'Offline',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('View Profile'),
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to profile
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.block),
                      title: const Text('Block User'),
                      onTap: () {
                        Navigator.pop(context);
                        // Show block confirmation
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : error.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(error),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              isLoading = true;
                              error = '';
                            });
                            _initializeChat();
                          },
                          child: const Text('Retry Connection'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: _messagesStream,
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              print('Stream error: ${snapshot.error}');
                              return Center(child: Text('Error: ${snapshot.error}'));
                            }

                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final messages = snapshot.data?.docs ?? [];
                            if (messages.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No messages yet',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Start the conversation with ${widget.doctor['name']}!',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return ListView.builder(
                              reverse: true,
                              padding: const EdgeInsets.all(16),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final message = messages[index].data() as Map<String, dynamic>;
                                final messageId = messages[index].id;
                                final isMe = message['senderId'] == (_auth.currentUser?.uid ?? _authToken);
                                final senderName = message['senderName'] ?? (isMe ? 'You' : 'Doctor');
                                final messageStatus = message['status'] ?? 'sent';
                                final isEdited = message['isEdited'] ?? false;
                                
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (!isMe) ...[
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundImage: NetworkImage(widget.doctor['image'] ?? ''),
                                          child: widget.doctor['image'] == null
                                              ? const Icon(Icons.person, size: 16)
                                              : null,
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Flexible(
                                        child: GestureDetector(
                                          onLongPress: isMe ? () {
                                            showModalBottomSheet(
                                              context: context,
                                              builder: (context) => Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  ListTile(
                                                    leading: const Icon(Icons.edit),
                                                    title: const Text('Edit Message'),
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                      _startEditing(messageId, message['text']);
                                                    },
                                                  ),
                                                  ListTile(
                                                    leading: const Icon(Icons.delete, color: Colors.red),
                                                    title: const Text('Delete Message', style: TextStyle(color: Colors.red)),
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                      showDialog(
                                                        context: context,
                                                        builder: (context) => AlertDialog(
                                                          title: const Text('Delete Message'),
                                                          content: const Text('Are you sure you want to delete this message?'),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () => Navigator.pop(context),
                                                              child: const Text('Cancel'),
                                                            ),
                                                            TextButton(
                                                              onPressed: () {
                                                                Navigator.pop(context);
                                                                _deleteMessage(messageId);
                                                              },
                                                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            );
                                          } : null,
                                          child: Container(
                                            constraints: BoxConstraints(
                                              maxWidth: MediaQuery.of(context).size.width * 0.7,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isMe ? Colors.blue : Colors.white,
                                              borderRadius: BorderRadius.only(
                                                topLeft: const Radius.circular(20),
                                                topRight: const Radius.circular(20),
                                                bottomLeft: Radius.circular(isMe ? 20 : 5),
                                                bottomRight: Radius.circular(isMe ? 5 : 20),
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.1),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                if (!isMe) ...[
                                                  Text(
                                                    senderName,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                ],
                                                Text(
                                                  message['text'],
                                                  style: TextStyle(
                                                    color: isMe ? Colors.white : Colors.black,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    if (isEdited) ...[
                                                      Text(
                                                        'edited',
                                                        style: TextStyle(
                                                          color: isMe ? Colors.white70 : Colors.grey[600],
                                                          fontSize: 10,
                                                          fontStyle: FontStyle.italic,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                    ],
                                                    Text(
                                                      message['timestamp'] != null
                                                          ? DateFormat('hh:mm a').format(
                                                              (message['timestamp'] as Timestamp).toDate(),
                                                            )
                                                          : '',
                                                      style: TextStyle(
                                                        color: isMe ? Colors.white70 : Colors.grey[600],
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                    if (isMe) ...[
                                                      const SizedBox(width: 4),
                                                      Icon(
                                                        messageStatus == 'sent' ? Icons.check : Icons.check_circle,
                                                        size: 12,
                                                        color: Colors.white70,
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (isMe) ...[
                                        const SizedBox(width: 8),
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: Colors.blue,
                                          child: Icon(
                                            Icons.person,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            if (_isEditing) ...[
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: _cancelEditing,
                              ),
                            ] else ...[
                              IconButton(
                                icon: const Icon(Icons.attach_file, color: Colors.blue),
                                onPressed: () {
                                  // Handle attachment
                                },
                              ),
                            ],
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                decoration: InputDecoration(
                                  hintText: _isEditing ? 'Edit message...' : 'Type a message...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                ),
                                maxLines: null,
                                onSubmitted: (_) => _isEditing ? _updateMessage() : sendMessage(),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                _isEditing ? Icons.check : Icons.send,
                                color: Colors.blue,
                              ),
                              onPressed: _isEditing ? _updateMessage : sendMessage,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
} 