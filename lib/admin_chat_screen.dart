import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AdminChatScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final String chatRoomId;

  const AdminChatScreen({Key? key, required this.user, required this.chatRoomId}) : super(key: key);

  @override
  _AdminChatScreenState createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TextEditingController _messageController;
  late String _chatRoomId;
  late bool isLoading;
  late String error;
  late Stream<QuerySnapshot> _messagesStream;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _chatRoomId = widget.chatRoomId;
    isLoading = true;
    error = '';
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    try {
      final user = _auth.currentUser;
      if (user == null || _chatRoomId == null) return;

      // Get messages stream
      _messagesStream = _firestore
          .collection('chatRooms')
          .doc(_chatRoomId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots();

      // Get admin details
      final adminDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!adminDoc.exists) {
        throw Exception('Admin document not found');
      }
      final adminData = adminDoc.data()!;
      final adminName = adminData['name'] ?? 'Admin';

      // Update chat room with last message
      await _firestore.collection('chatRooms').doc(_chatRoomId).update({
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': user.uid,
        'lastMessageSenderName': adminName,
        'status': 'active',
        'unreadCount': FieldValue.increment(1),
      });

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        error = 'Failed to connect to the chat: $e';
      });
    }
  }

  Future<void> sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      final user = _auth.currentUser;
      if (user == null || _chatRoomId == null) return;

      // Get admin details
      final adminDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!adminDoc.exists) {
        throw Exception('Admin document not found');
      }
      final adminData = adminDoc.data()!;
      final adminName = adminData['name'] ?? 'Admin';

      final message = {
        'text': _messageController.text.trim(),
        'senderId': user.uid,
        'senderName': adminName,
        'timestamp': FieldValue.serverTimestamp(),
        'isAdmin': true,
        'type': 'text',
        'status': 'sent',
      };

      // Add message to messages collection
      await _firestore
          .collection('chatRooms')
          .doc(_chatRoomId)
          .collection('messages')
          .add(message);

      // Update chat room with last message
      await _firestore.collection('chatRooms').doc(_chatRoomId).update({
        'lastMessage': _messageController.text.trim(),
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': user.uid,
        'lastMessageSenderName': adminName,
        'status': 'active',
        'unreadCount': FieldValue.increment(1),
      });

      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(widget.user['image'] ?? ''),
              radius: 20,
              child: widget.user['image'] == null
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user['name'] ?? 'Unknown User',
                  style: const TextStyle(color: Colors.white),
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
          ],
        ),
      ),
      body: isLoading
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
                                    'Start the conversation with ${widget.user['name']}!',
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
                              final isMe = message['senderId'] == _auth.currentUser?.uid;
                              final senderName = message['senderName'] ?? (isMe ? 'You' : 'User');
                              final messageStatus = message['status'] ?? 'sent';
                              
                              return Align(
                                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMe ? Colors.blue : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        senderName,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isMe ? Colors.white70 : Colors.grey[600],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
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
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: const InputDecoration(
                                hintText: 'Type a message...',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: null,
                              onSubmitted: (_) => sendMessage(),
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
} 