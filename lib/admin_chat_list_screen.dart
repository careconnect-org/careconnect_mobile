import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'admin_chat_screen.dart';

class AdminChatListScreen extends StatefulWidget {
  const AdminChatListScreen({Key? key}) : super(key: key);

  @override
  _AdminChatListScreenState createState() => _AdminChatListScreenState();
}

class _AdminChatListScreenState extends State<AdminChatListScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  String _error = '';
  List<Map<String, dynamic>> _chatRooms = [];

  @override
  void initState() {
    super.initState();
    _loadChatRooms();
  }

  Future<void> _loadChatRooms() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final chatRoomsSnapshot = await _firestore
          .collection('chatRooms')
          .where('participants', arrayContains: user.uid)
          .orderBy('lastMessageTime', descending: true)
          .get();

      final List<Map<String, dynamic>> chatRooms = [];
      for (var doc in chatRoomsSnapshot.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants']);
        final otherUserId = participants.firstWhere((id) => id != user.uid);
        
        // Get user details
        final userDoc = await _firestore.collection('users').doc(otherUserId).get();
        if (!userDoc.exists) continue;

        final userData = userDoc.data()!;
        chatRooms.add({
          'id': doc.id,
          'user': {
            'id': otherUserId,
            'name': userData['name'] ?? 'Unknown User',
            'image': userData['image'],
          },
          'lastMessage': data['lastMessage'] ?? '',
          'lastMessageTime': data['lastMessageTime'],
          'lastMessageSender': data['lastMessageSender'],
          'lastMessageSenderName': data['lastMessageSenderName'],
          'unreadCount': data['unreadCount'] ?? 0,
          'status': data['status'] ?? 'inactive',
        });
      }

      setState(() {
        _chatRooms = chatRooms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat List'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadChatRooms,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error))
              : _chatRooms.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'No chats yet',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start a conversation with a user!',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _chatRooms.length,
                      itemBuilder: (context, index) {
                        final chatRoom = _chatRooms[index];
                        final user = chatRoom['user'];
                        final lastMessage = chatRoom['lastMessage'];
                        final lastMessageTime = chatRoom['lastMessageTime'] as Timestamp?;
                        final lastMessageSender = chatRoom['lastMessageSender'];
                        final lastMessageSenderName = chatRoom['lastMessageSenderName'];
                        final unreadCount = chatRoom['unreadCount'] as int? ?? 0;
                        final isActive = chatRoom['status'] == 'active';

                        return ListTile(
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                backgroundImage: user['image'] != null
                                    ? NetworkImage(user['image'])
                                    : null,
                                child: user['image'] == null
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              if (isActive)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  user['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (unreadCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    unreadCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (lastMessageSenderName != null)
                                Text(
                                  'By $lastMessageSenderName',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                lastMessageTime != null
                                    ? DateFormat('MMM d, h:mm a')
                                        .format(lastMessageTime.toDate())
                                    : '',
                                style: const TextStyle(fontSize: 12),
                              ),
                              if (isActive)
                                const Text(
                                  'Online',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green,
                                  ),
                                ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AdminChatScreen(
                                  user: user,
                                  chatRoomId: chatRoom['id'],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
    );
  }
} 