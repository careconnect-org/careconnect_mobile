import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/admin_messaging_service.dart';

class AdminChatScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const AdminChatScreen({
    Key? key,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final AdminMessagingService _messagingService = AdminMessagingService();
  String? _chatRoomId;
  bool _isLoading = true;
  bool _isSending = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      print('Initializing chat with userId/token: ${widget.userId}');
      _chatRoomId = await _messagingService.getOrCreateChatRoom(widget.userId);
      print('Chat room created/found with ID: $_chatRoomId');
      
      if (_chatRoomId == null) {
        throw Exception('Failed to create chat room');
      }

      // Verify chat room exists and has correct data
      final chatRoomDoc = await _firestore.collection('chatRooms').doc(_chatRoomId).get();
      if (!chatRoomDoc.exists) {
        throw Exception('Chat room not found');
      }

      final data = chatRoomDoc.data()!;
      if (data['userId'] == null || data['userName'] == null) {
        throw Exception('Invalid chat room data');
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error initializing chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message cannot be empty'),
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

    if (_isSending) return;

    final message = _messageController.text.trim();
    setState(() {
      _isSending = true;
    });
    _messageController.clear(); // Clear immediately for better UX

    try {
      print('Sending message: $message');
      await _messagingService.sendMessage(_chatRoomId!, message);
      print('Message sent successfully');
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: Colors.red,
        ),
      );
      // Restore the message if sending failed
      _messageController.text = message;
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_chatRoomId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.userName),
        ),
        body: const Center(
          child: Text('Failed to initialize chat room'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.userName),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.message),
            onPressed: () async {
              try {
                await _messagingService.sendSampleMessage(_chatRoomId!);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sample message sent'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to send sample message: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            tooltip: 'Send sample message',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messagingService.getMessages(_chatRoomId!),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print('Stream error: ${snapshot.error}');
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;
                print('Received ${messages.length} messages');
                
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
                          'Start the conversation with ${widget.userName}!',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              await _messagingService.sendSampleMessage(_chatRoomId!);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to send sample message: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.message),
                          label: const Text('Send Sample Message'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index].data() as Map<String, dynamic>;
                    print('Message data: $message');
                    
                    // Validate message data
                    if (message['senderName'] == null || message['text'] == null) {
                      print('Invalid message data: $message');
                      return const SizedBox.shrink(); // Skip invalid messages
                    }

                    final isAdmin = message['isAdmin'] ?? false;
                    final senderName = message['senderName'] ?? (isAdmin ? 'Admin' : 'User');
                    final messageText = message['text'] ?? '';
                    final messageStatus = message['status'] ?? 'sent';
                    final timestamp = message['timestamp'] as Timestamp?;
                    final timeString = timestamp != null 
                        ? '${timestamp.toDate().hour}:${timestamp.toDate().minute.toString().padLeft(2, '0')}'
                        : '';

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Column(
                        crossAxisAlignment: isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: isAdmin ? MainAxisAlignment.end : MainAxisAlignment.start,
                            children: [
                              Text(
                                senderName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                timeString,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isAdmin ? Colors.blue : Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    messageText,
                                    style: TextStyle(
                                      color: isAdmin ? Colors.white : Colors.black,
                                    ),
                                  ),
                                ),
                                if (isAdmin) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    messageStatus == 'sent' ? Icons.check : Icons.check_circle,
                                    size: 16,
                                    color: Colors.white70,
                                  ),
                                ],
                              ],
                            ),
                          ),
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
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
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
                    onSubmitted: (_) => _sendMessage(),
                    enabled: !_isSending,
                  ),
                ),
                IconButton(
                  icon: _isSending
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  onPressed: _isSending ? null : _sendMessage,
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