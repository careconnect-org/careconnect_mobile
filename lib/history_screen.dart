import 'chatdetailscreen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MessageHistoryScreen extends StatefulWidget {
  const MessageHistoryScreen({Key? key}) : super(key: key);

  @override
  State<MessageHistoryScreen> createState() => _MessageHistoryScreenState();
}

class _MessageHistoryScreenState extends State<MessageHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> chats = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    loadChats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(automaticallyImplyLeading: false,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.blue,
        title: Row(
          children: [
            Icon(Icons.medical_services, color: Colors.white),
            const SizedBox(width: 8),
            const Text(
              "History",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "Message"),
            Tab(text: "Voice Call"),
            Tab(text: "Video Call"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMessageList(),
          _buildCallList(isVideo: false),
          _buildCallList(isVideo: true),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (chats.isEmpty) {
      return const Center(child: Text('No chat history found.'));
    }
    return ListView.builder(
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];
        final doctor = chat['doctor']['user'];
        final lastMessage = chat['lastMessage'];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(doctor['image']),
          ),
          title: Text('${doctor['firstName']} ${doctor['lastName']}'),
          subtitle: Text(lastMessage['text']),
          trailing: Text(DateFormat('hh:mm a').format(DateTime.parse(lastMessage['createdAt']))),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatDetailScreen(doctor: chat['doctor']),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCallList({required bool isVideo}) {
    return Center(
      child: Text(
        isVideo ? "Video Call History" : "Voice Call History",
        style: const TextStyle(fontSize: 18),
      ),
    );
  }

  Future<void> loadChats() async {
    chats = await fetchUserChats();
    setState(() {
      isLoading = false;
    });
  }

  Future<List<Map<String, dynamic>>> fetchUserChats() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userId = prefs.getString('user_id');
    if (token == null || userId == null) return [];

    final response = await http.get(
      Uri.parse('https://careconnect-api-v2kw.onrender.com/api/chat/user/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map<Map<String, dynamic>>((chat) => chat as Map<String, dynamic>).toList();
    }
    return [];
  }
}
