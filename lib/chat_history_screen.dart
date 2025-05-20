import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'chat_screen.dart';
import 'available_doctors_screen.dart';

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _doctors = [];
  List<Map<String, dynamic>> _chatRooms = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _error = 'Please login to view messages';
          _isLoading = false;
        });
        return;
      }

      // First, get all chat rooms where the user is a participant
      final chatRoomsSnapshot = await _firestore
          .collection('chatRooms')
          .where('participants', arrayContains: user.uid)
          .orderBy('lastMessageTime', descending: true)
          .get();

      if (chatRoomsSnapshot.docs.isEmpty) {
        setState(() {
          _chatRooms = [];
          _isLoading = false;
        });
        return;
      }

      // Get all doctor IDs from chat rooms
      final doctorIds = chatRoomsSnapshot.docs.map((doc) {
        final data = doc.data();
        final participants = List<String>.from(data['participants']);
        return participants.firstWhere((id) => id != user.uid);
      }).toList();

      // Fetch doctors' information from your API
      final response = await http.get(
        Uri.parse('https://careconnect-api-v2kw.onrender.com/api/doctor/all'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> allDoctors = json.decode(response.body);

        // Filter doctors to only include those with chat rooms
        final List<Map<String, dynamic>> doctors = allDoctors
            .where((doctor) => doctorIds.contains(doctor['_id']))
            .map((doctor) => {
                  'id': doctor['_id'],
                  'name': '${doctor['firstName']} ${doctor['lastName']}',
                  'specialty': doctor['specialty'],
                  'image': doctor['image'],
                })
            .toList();

        // Create a map of doctor IDs to their information for quick lookup
        final Map<String, Map<String, dynamic>> doctorMap = {
          for (var doctor in doctors) doctor['id']: doctor
        };

        // Combine chat room data with doctor information
        final List<Map<String, dynamic>> chatRooms = await Future.wait(
          chatRoomsSnapshot.docs.map((doc) async {
            final data = doc.data();
            final participants = List<String>.from(data['participants']);
            final doctorId = participants.firstWhere((id) => id != user.uid);
            final doctor = doctorMap[doctorId] ??
                {
                  'id': doctorId,
                  'name': 'Unknown Doctor',
                  'specialty': 'General',
                  'image': null,
                };

            // Get the last message from the messages collection
            final lastMessageDoc = await _firestore
                .collection('chatRooms')
                .doc(doc.id)
                .collection('messages')
                .orderBy('timestamp', descending: true)
                .limit(1)
                .get();

            final lastMessage = lastMessageDoc.docs.isNotEmpty
                ? lastMessageDoc.docs.first.data()
                : null;

            // Update chat room status to active
            await _firestore.collection('chatRooms').doc(doc.id).update({
              'status': 'active',
              'updatedAt': FieldValue.serverTimestamp(),
            });

            return {
              'id': doc.id,
              'doctor': doctor,
              'lastMessage': lastMessage?['text'] ?? data['lastMessage'] ?? '',
              'lastMessageTime':
                  lastMessage?['timestamp'] ?? data['lastMessageTime'],
              'lastMessageSender':
                  lastMessage?['senderId'] ?? data['lastMessageSender'],
              'lastMessageSenderName':
                  lastMessage?['senderName'] ?? data['lastMessageSenderName'],
              'unreadCount': data['unreadCount'] ?? 0,
              'status': 'active',
              'createdAt': data['createdAt'],
              'updatedAt': FieldValue.serverTimestamp(),
            };
          }),
        );

        // Sort chat rooms by last message time
        chatRooms.sort((a, b) {
          final aTime = a['lastMessageTime'] as Timestamp?;
          final bTime = b['lastMessageTime'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        setState(() {
          _chatRooms = chatRooms;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load doctors');
      }
    } catch (e) {
      print('Error loading chat history: $e');
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  // Find active chat with a specific doctor by ID
  Future<Map<String, dynamic>?> findActiveChatWithDoctor(
      String doctorId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      for (var chatRoom in _chatRooms) {
        // Check if the doctor is a participant in this chat room
        if (chatRoom['doctor']['id'] == doctorId) {
          print('Found existing chat room with doctor: $doctorId');
          return chatRoom;
        }
      }

      // If not found in local state, try querying Firestore directly
      final chatRoomsSnapshot = await _firestore
          .collection('chatRooms')
          .where('participants', arrayContains: user.uid)
          .get();

      for (var doc in chatRoomsSnapshot.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants']);
        if (participants.contains(doctorId)) {
          print('Found existing chat room in Firestore with doctor: $doctorId');
          // Fetch doctor info and return chat room
          final doctor = await _fetchDoctorById(doctorId);
          return {
            'id': doc.id,
            'doctor': doctor,
            'lastMessage': data['lastMessage'] ?? '',
            'lastMessageTime': data['lastMessageTime'],
          };
        }
      }

      return null; // No active chat found with this doctor
    } catch (e) {
      print('Error finding active chat: $e');
      return null;
    }
  }

  // Fetch doctor information by ID
  Future<Map<String, dynamic>> _fetchDoctorById(String doctorId) async {
    try {
      // Try to find doctor in existing list first
      for (var chatRoom in _chatRooms) {
        if (chatRoom['doctor']['id'] == doctorId) {
          return chatRoom['doctor'];
        }
      }

      // If not found, fetch from API
      final response = await http.get(
        Uri.parse(
            'https://careconnect-api-v2kw.onrender.com/api/doctor/$doctorId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final doctor = json.decode(response.body);
        return {
          'id': doctor['_id'],
          'name': '${doctor['firstName']} ${doctor['lastName']}',
          'specialty': doctor['specialty'],
          'image': doctor['image'],
        };
      } else {
        // Return generic doctor info if API fails
        return {
          'id': doctorId,
          'name': 'Doctor',
          'specialty': 'Unknown',
          'image': null,
        };
      }
    } catch (e) {
      print('Error fetching doctor: $e');
      return {
        'id': doctorId,
        'name': 'Doctor',
        'specialty': 'Unknown',
        'image': null,
      };
    }
  }

  // Show dialog with list of active chats
  void _showActiveChatsList() {
    if (_chatRooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active chats found'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxHeight: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Your Active Chats',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _chatRooms.length,
                  itemBuilder: (context, index) {
                    final chatRoom = _chatRooms[index];
                    final doctor = chatRoom['doctor'];

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: doctor['image'] != null
                            ? NetworkImage(doctor['image'])
                            : null,
                        child: doctor['image'] == null
                            ? const Icon(Icons.person, size: 20)
                            : null,
                      ),
                      title: Text(doctor['name']),
                      subtitle: Text(
                        chatRoom['lastMessage'] ?? 'No messages yet',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              doctor: doctor,
                              existingChatRoomId: chatRoom['id'],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat History'),
        backgroundColor: Colors.blue,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _chatRooms.isEmpty
                    ? _buildMessageList()
                    : ListView.builder(
                        itemCount: _chatRooms.length,
                        itemBuilder: (context, index) {
                          final chatRoom = _chatRooms[index];
                          final doctor = chatRoom['doctor'];
                          final lastMessage = chatRoom['lastMessage'];
                          final lastMessageTime =
                              chatRoom['lastMessageTime'] as Timestamp?;
                          final lastMessageSender =
                              chatRoom['lastMessageSender'];
                          final lastMessageSenderName =
                              chatRoom['lastMessageSenderName'];
                          final unreadCount =
                              chatRoom['unreadCount'] as int? ?? 0;
                          final isActive = chatRoom['status'] == 'active';

                          return Hero(
                            tag: 'doctor_${doctor['id']}',
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ChatScreen(doctor: doctor),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey.withOpacity(0.1),
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Stack(
                                        children: [
                                          CircleAvatar(
                                            radius: 30,
                                            backgroundImage: doctor['image'] !=
                                                    null
                                                ? NetworkImage(doctor['image'])
                                                : null,
                                            child: doctor['image'] == null
                                                ? const Icon(Icons.person,
                                                    size: 30)
                                                : null,
                                          ),
                                          if (isActive)
                                            Positioned(
                                              right: 0,
                                              bottom: 0,
                                              child: Container(
                                                width: 14,
                                                height: 14,
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
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    doctor['name'],
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                                if (unreadCount > 0)
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
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
                                            const SizedBox(height: 4),
                                            Text(
                                              lastMessage,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                            if (lastMessageSenderName !=
                                                null) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'By $lastMessageSenderName',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[500],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            lastMessageTime != null
                                                ? DateFormat('MMM d, h:mm a')
                                                    .format(lastMessageTime
                                                        .toDate())
                                                : '',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          if (isActive) ...[
                                            const SizedBox(height: 4),
                                            const Text(
                                              'Online',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AvailableDoctorsScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildMessageList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No active chats yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start a conversation with a doctor',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AvailableDoctorsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add_comment),
                label: const Text('Start New Chat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 2,
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _showActiveChatsList(),
                icon: const Icon(Icons.chat_bubble),
                label: const Text('Active Chats'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
