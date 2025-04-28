import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ChatDetailScreen extends StatefulWidget {
  final Map<String, dynamic> doctor;

  const ChatDetailScreen({Key? key, required this.doctor}) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  String? chatId;
  bool isLoading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    setupChat();
  }

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id'); // Make sure you store this at login
  }

  Future<String?> getOrCreateChatId(String doctorId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userId = prefs.getString('user_id'); // Make sure you store this at login

    if (token == null || userId == null) return null;

    // 1. Try to create a chat (API should return existing chat if already created)
    final response = await http.post(
      Uri.parse('https://careconnect-api-v2kw.onrender.com/api/chat/create'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'userId': userId, 'doctorId': doctorId}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return data['chat']?['_id'] ?? data['_id']; // Adjust based on your API response
    } else {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchMessages(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return [];

    final response = await http.get(
      Uri.parse('https://careconnect-api-v2kw.onrender.com/api/chat/$chatId'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> messages = data['messages'] ?? [];
      final userId = await _getUserId();
      return messages.map((msg) => {
        'id': msg['_id'],
        'text': msg['text'],
        'sender': msg['sender'],
        'timestamp': msg['createdAt'],
        'isMe': msg['sender'] == userId,
      }).toList();
    }
    return [];
  }

  Future<bool> sendMessage(String chatId, String text) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return false;

    final response = await http.post(
      Uri.parse('https://careconnect-api-v2kw.onrender.com/api/chat/message/$chatId'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'text': text}),
    );

    return response.statusCode == 201;
  }

  Future<void> setupChat() async {
    chatId = await getOrCreateChatId(widget.doctor['id']);
    if (chatId != null) {
      _messages = await fetchMessages(chatId!);
      setState(() { isLoading = false; });
    } else {
      setState(() { error = 'Could not start chat.'; isLoading = false; });
    }
  }

  Future<void> handleSend() async {
    if (chatId != null && _messageController.text.trim().isNotEmpty) {
      final sent = await sendMessage(chatId!, _messageController.text.trim());
      if (sent) {
        _messageController.clear();
        _messages = await fetchMessages(chatId!);
        setState(() {});
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
        title: Text(
          (widget.doctor['name']),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? Center(child: Text(error))
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
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return _buildMessageBubble(
                            message['text'],
                            message['isMe'],
                            message['timestamp'],
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
                            onPressed: handleSend,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildMessageBubble(String text, bool isUser, String time) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue : Colors.white,
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
                color: isUser ? Colors.white : Colors.black,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: isUser ? Colors.white70 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
                if (isUser)
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