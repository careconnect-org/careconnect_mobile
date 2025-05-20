import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/chat_service.dart';
import 'models/doctor.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/chat_screen.dart';

class MyFavoriteDoctorScreen extends StatefulWidget {
  const MyFavoriteDoctorScreen({Key? key}) : super(key: key);

  @override
  State<MyFavoriteDoctorScreen> createState() => _MyFavoriteDoctorScreenState();
}

class _MyFavoriteDoctorScreenState extends State<MyFavoriteDoctorScreen> {
  final ChatService _chatService = ChatService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? currentUserId;
  List<Doctor> favoriteDoctors = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserId = prefs.getString('user_id');
    });
    if (currentUserId != null) {
      _loadFavoriteDoctors();
    }
  }

  Future<void> _loadFavoriteDoctors() async {
    try {
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      final favoriteDoctorIds = List<String>.from(userDoc.data()?['favoriteDoctors'] ?? []);

      final doctorsSnapshot = await _firestore
          .collection('doctors')
          .where(FieldPath.documentId, whereIn: favoriteDoctorIds)
          .get();

      setState(() {
        favoriteDoctors = doctorsSnapshot.docs.map((doc) {
          final data = doc.data();
          return Doctor(
            id: doc.id,
            name: data['name'] ?? '',
            specialty: data['specialty'] ?? '',
            imageUrl: data['imageUrl'] ?? '',
            isFavorite: true,
          );
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading favorite doctors: $e')),
      );
    }
  }

  Future<void> _startChat(String doctorId) async {
    if (currentUserId == null) return;
    
    try {
      await _chatService.ensureChatChannel(doctorId);
      if (!mounted) return;
      
      // Get doctor's name from Firestore
      final doctorDoc = await _firestore.collection('doctors').doc(doctorId).get();
      final doctorName = doctorDoc.data()?['name'] ?? 'Doctor';
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            receiverId: doctorId,
            receiverName: doctorName,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting chat: $e')),
      );
    }
  }

  Future<void> _toggleFavorite(Doctor doctor) async {
    if (currentUserId == null) return;

    try {
      final userRef = _firestore.collection('users').doc(currentUserId);
      final userDoc = await userRef.get();
      final favoriteDoctors = List<String>.from(userDoc.data()?['favoriteDoctors'] ?? []);

      if (doctor.isFavorite) {
        favoriteDoctors.remove(doctor.id);
      } else {
        favoriteDoctors.add(doctor.id);
      }

      await userRef.update({'favoriteDoctors': favoriteDoctors});
      _loadFavoriteDoctors(); // Reload the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating favorite status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Favorite Doctors'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: favoriteDoctors.isEmpty
          ? const Center(
              child: Text('No favorite doctors yet'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: favoriteDoctors.length,
              itemBuilder: (context, index) {
                final doctor = favoriteDoctors[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: doctor.imageUrl.isNotEmpty
                          ? NetworkImage(doctor.imageUrl)
                          : const AssetImage('assets/images/avatar.png') as ImageProvider,
                    ),
                    title: Text(doctor.name),
                    subtitle: Text(doctor.specialty),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.favorite,
                            color: doctor.isFavorite ? Colors.red : Colors.grey,
                          ),
                          onPressed: () => _toggleFavorite(doctor),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chat),
                          onPressed: () => _startChat(doctor.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
} 