import 'package:careconnect/available_patients_screen.dart';
import 'package:careconnect/chatdetailscreen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminMessageHistoryScreen extends StatefulWidget {
  const AdminMessageHistoryScreen({Key? key}) : super(key: key);

  @override
  State<AdminMessageHistoryScreen> createState() => _AdminMessageHistoryScreenState();
}

class _AdminMessageHistoryScreenState extends State<AdminMessageHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> chats = [];
  bool isLoading = true;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.blue,
        title: Row(
          children: [
            Icon(Icons.medical_services, color: Colors.white),
            const SizedBox(width: 8),
            const Text(
              "Admin History",
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              "No active chats yet",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              "Start a conversation with a patient",
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AvailablePatientsScreen(),
                  ),
                );
              },
              child: const Text("Start New Chat"),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];
        final lastMessage = chat['lastMessage'] as String? ?? '';
        final lastMessageTime = chat['lastMessageTime'] as Timestamp?;
        final otherUser = chat['otherUser'] as Map<String, dynamic>;

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: otherUser['image'] != null
                ? NetworkImage(otherUser['image'])
                : null,
            child: otherUser['image'] == null
                ? const Icon(Icons.person)
                : null,
          ),
          title: Text(otherUser['name'] ?? 'Unknown User'),
          subtitle: Text(
            lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            lastMessageTime != null
                ? DateFormat('MMM d, h:mm a').format(lastMessageTime.toDate())
                : '',
            style: const TextStyle(fontSize: 12),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatDetailScreen(
                  doctor: {
                    'id': otherUser['id'],
                    'name': otherUser['name'],
                    'image': otherUser['image'],
                  },
                ),
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
    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final chatRoomsSnapshot = await _firestore
          .collection('chatRooms')
          .where('participants', arrayContains: user.uid)
          .orderBy('lastMessageTime', descending: true)
          .get();

      final List<Map<String, dynamic>> chatList = [];
      
      for (var doc in chatRoomsSnapshot.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants']);
        final otherUserId = participants.firstWhere((id) => id != user.uid);
        
        // Fetch other user's details
        final userDoc = await _firestore.collection('users').doc(otherUserId).get();
        final userData = userDoc.data() ?? {};
        
        chatList.add({
          'id': doc.id,
          'lastMessage': data['lastMessage'],
          'lastMessageTime': data['lastMessageTime'],
          'otherUser': {
            'id': otherUserId,
            'name': userData['name'] ?? 'Unknown User',
            'image': userData['image'],
          },
        });
      }

      setState(() {
        chats = chatList;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading chats: $e');
      setState(() {
        isLoading = false;
      });
    }
  }
} 