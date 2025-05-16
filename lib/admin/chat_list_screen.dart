import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../screens/chat_screen.dart';

class AdminChatListScreen extends StatefulWidget {
  const AdminChatListScreen({Key? key}) : super(key: key);

  @override
  State<AdminChatListScreen> createState() => _AdminChatListScreenState();
}

class _AdminChatListScreenState extends State<AdminChatListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final response = await http.get(
        Uri.parse('https://careconnect-api-v2kw.onrender.com/api/user/all'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _users = data.map((user) => {
            'id': user['_id'],
            'name': user['name'],
            'image': user['image'],
            'email': user['email'],
            'phone': user['phone'],
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to fetch users';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _getChatRoomDetails(String userId) async {
    final user = _auth.currentUser;
    if (user == null) return {};

    final chatRoomId = user.uid.compareTo(userId) < 0
        ? '${user.uid}_$userId'
        : '${userId}_${user.uid}';

    final chatRoomDoc = await _firestore.collection('chatRooms').doc(chatRoomId).get();
    return chatRoomDoc.data() ?? {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchUsers,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error))
              : _users.isEmpty
                  ? const Center(child: Text('No users available'))
                  : ListView.builder(
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return FutureBuilder<Map<String, dynamic>>(
                          future: _getChatRoomDetails(user['id']),
                          builder: (context, snapshot) {
                            final chatRoom = snapshot.data ?? {};
                            final lastMessage = chatRoom['lastMessage'] as String? ?? '';
                            final lastMessageTime = chatRoom['lastMessageTime'] as Timestamp?;

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: user['image'] != null
                                    ? NetworkImage(user['image'])
                                    : null,
                                child: user['image'] == null
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              title: Text(user['name'] ?? 'Unknown User'),
                              subtitle: Text(
                                lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Text(
                                lastMessageTime != null
                                    ? DateFormat('MMM d, h:mm a')
                                        .format(lastMessageTime.toDate())
                                    : '',
                                style: const TextStyle(fontSize: 12),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      otherUserId: user['id'],
                                      otherUserName: user['name'] ?? 'Unknown User',
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
    );
  }
} 