import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/firebase_messaging_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatDetailScreen extends StatefulWidget {
  final Map<String, dynamic> doctor;

  const ChatDetailScreen({Key? key, required this.doctor}) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _chatRoomId;
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  String _error = '';

  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      print('Retrieved token: ${token != null ? 'Token exists' : 'No token found'}');
      return token;
    } catch (e) {
      print('Error getting token: $e');
      return null;
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
        setState(() {
          _error = 'Please login to chat';
          _isLoading = false;
        });
        return;
      }

      // Create or get chat room ID
      final chatRoomId = await _getOrCreateChatRoom(user.uid, widget.doctor['id']);

      setState(() {
        _chatRoomId = chatRoomId;
      });

      // Set up message listener
      _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .listen((snapshot) {
        setState(() {
          _messages = snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'text': data['text'],
              'senderId': data['senderId'],
              'timestamp': data['timestamp'],
            };
          }).toList();
          _isLoading = false;
        });
      });
    } catch (e) {
      setState(() {
        _error = 'Error initializing chat: $e';
        _isLoading = false;
      });
    }
  }

  Future<String> _getOrCreateChatRoom(String userId, String doctorId) async {
    // Create a unique chat room ID by combining user IDs
    final chatRoomId = userId.compareTo(doctorId) < 0
        ? '${userId}_$doctorId'
        : '${doctorId}_$userId';

    // Check if chat room exists
    final chatRoomDoc = await _firestore.collection('chatRooms').doc(chatRoomId).get();

    if (!chatRoomDoc.exists) {
      // Create new chat room
      await _firestore.collection('chatRooms').doc(chatRoomId).set({
        'participants': [userId, doctorId],
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return chatRoomId;
  }

  Future<void> sendMessage() async {
    if (_messageController.text.trim().isEmpty || _chatRoomId == null) return;

    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _error = 'Please login to send messages';
        });
        return;
      }

      final message = {
        'text': _messageController.text.trim(),
        'senderId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Add message to chat room
      await _firestore
          .collection('chatRooms')
          .doc(_chatRoomId)
          .collection('messages')
          .add(message);

      // Update chat room with last message
      await _firestore.collection('chatRooms').doc(_chatRoomId).update({
        'lastMessage': _messageController.text.trim(),
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
    } catch (e) {
      setState(() {
        _error = 'Error sending message: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.doctor['image'] != null
                  ? NetworkImage(widget.doctor['image'])
                  : null,
              child: widget.doctor['image'] == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              widget.doctor['name'],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error))
              : Column(
                  children: [
                    // Session info bar
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      color: Colors.grey[200],
                      child: const Center(
                        child: Text(
                          "Session Start",
                          style: TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    // Chat messages
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _error.isNotEmpty
                              ? Center(child: Text(_error))
                              : ListView.builder(
                                  reverse: true,
                                  itemCount: _messages.length,
                                  itemBuilder: (context, index) {
                                    final message = _messages[index];
                                    final isMe = message['senderId'] == _auth.currentUser?.uid;

                                    return Align(
                                      alignment: isMe
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 4,
                                          horizontal: 8,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isMe ? Colors.blue : Colors.grey[300],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          message['text'],
                                          style: TextStyle(
                                            color: isMe ? Colors.white : Colors.black,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ),
                    // Input field
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      color: Colors.white,
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.attach_file),
                            onPressed: () {},
                          ),
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: "Type a message...",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey[200],
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send, color: Colors.blue),
                            onPressed: sendMessage,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}