import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'services/admin_messaging_service.dart';

class AdminChatDetailScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const AdminChatDetailScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<AdminChatDetailScreen> createState() => _AdminChatDetailScreenState();
}

class _AdminChatDetailScreenState extends State<AdminChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final AdminMessagingService _messagingService = AdminMessagingService();
  String? chatRoomId;
  bool isLoading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    setupChat();
  }

  Future<void> setupChat() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Admin not authenticated');

      // Create chat room ID
      chatRoomId = user.uid.compareTo(widget.user['id']) < 0
          ? '${user.uid}_${widget.user['id']}'
          : '${widget.user['id']}_${user.uid}';

      // Check if chat room exists
      final chatRoomRef = FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(chatRoomId);
      final chatRoom = await chatRoomRef.get();

      if (!chatRoom.exists) {
        await chatRoomRef.set({
          'participants': [user.uid, widget.user['id']],
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastMessageSender': user.uid,
        });
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Could not start chat: $e';
        isLoading = false;
      });
    }
  }

  Future<void> handleSend() async {
    if (chatRoomId != null && _messageController.text.trim().isNotEmpty) {
      try {
        await _messagingService.sendMessage(
          chatRoomId!,
          _messageController.text.trim(),
        );
        _messageController.clear();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
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
              backgroundImage: widget.user['image'] != null
                  ? NetworkImage(widget.user['image'])
                  : null,
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
                const Text(
                  'Online',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              // Show more options
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? Center(child: Text(error))
              : Column(
                  children: [
                    // Chat messages
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _messagingService.getMessages(chatRoomId!),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(child: Text('Error: ${snapshot.error}'));
                          }

                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final messages = snapshot.data?.docs ?? [];
                          
                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index].data() as Map<String, dynamic>;
                              final isMe = message['senderId'] == FirebaseAuth.instance.currentUser?.uid;
                              
                              return _buildMessageBubble(
                                message['text'],
                                isMe,
                                message['timestamp']?.toDate().toString() ?? '',
                              );
                            },
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
                            onPressed: () {
                              // Handle file attachment
                            },
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
                            onPressed: handleSend,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe, String time) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('hh:mm a').format(DateTime.parse(time)),
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
                if (isMe)
                  const Icon(
                    Icons.check,
                    size: 14,
                    color: Colors.white70,
                  ),
              ],
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