import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Messages'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _chatService.getChatChannels(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data!;

          if (chats.isEmpty) {
            return Center(
              child: Text(
                'No conversations yet',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final participants = List<String>.from(chat['participants']);
              final otherUserId = participants.firstWhere(
                (id) => id != FirebaseAuth.instance.currentUser!.uid,
              );

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherUserId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return ListTile(
                      leading: CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      title: Text('Loading...'),
                    );
                  }

                  final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  final userName = '${userData['firstName']} ${userData['lastName']}';
                  final lastMessage = chat['lastMessage'] as String? ?? 'No messages yet';
                  final lastMessageTime = (chat['lastMessageTime'] as Timestamp?)?.toDate();

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: userData['image'] != null
                          ? NetworkImage(userData['image'])
                          : null,
                      child: userData['image'] == null
                          ? Icon(Icons.person)
                          : null,
                    ),
                    title: Text(userName),
                    subtitle: Text(
                      lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: lastMessageTime != null
                        ? Text(
                            _formatTime(lastMessageTime),
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          )
                        : null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            otherUserId: otherUserId,
                            otherUserName: userName,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
} 