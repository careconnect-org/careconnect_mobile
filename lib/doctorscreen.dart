import 'package:flutter/material.dart';
import 'package:careconnect/chatdetailscreen.dart';

class DoctorsPage extends StatelessWidget {
  DoctorsPage({super.key});

  static const List<Map<String, dynamic>> doctors = const [
    {
      'name': 'Dr. Aidan Allende',
      'specialty': 'Cardiologist',
      'rating': 4.8,
      'available': true,
      'workingHours': 'Mon-Fri, 9:00 AM - 5:00 PM',
      'image': 'https://i.pravatar.cc/150?img=32'
    },
    {
      'name': 'Dr. Iker Holl',
      'specialty': 'Dermatologist',
      'rating': 4.5,
      'available': true,
      'workingHours': 'Tue-Sat, 10:00 AM - 6:00 PM',
      'image': 'https://i.pravatar.cc/150?img=12'
    },
    {
      'name': 'Dr. Jada Srnsky',
      'specialty': 'Psychiatrist',
      'rating': 4.9,
      'available': false,
      'workingHours': 'Mon-Wed, 12:00 PM - 8:00 PM',
      'image': 'https://i.pravatar.cc/150?img=5'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text(
          "Our Doctors",
          style: TextStyle(
            color: Colors.white, // Set the text color
            fontSize: 18, // Set the font size
            fontWeight: FontWeight.bold, // Set the font weight
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue, // AppBar background color
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: doctors.length,
        itemBuilder: (context, index) {
          final doctor = doctors[index];
          return _buildDoctorCard(context, doctor);
        },
      ),
    );
  }

  Widget _buildDoctorCard(BuildContext context, Map<String, dynamic> doctor) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(doctor['image']),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        doctor['specialty'],
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        doctor['workingHours'],
                        style: const TextStyle(fontSize: 12),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star,
                              color: Colors.orange, size: 16),
                          Text("${doctor['rating']}"),
                          const SizedBox(width: 10),
                          Icon(
                            Icons.circle,
                            color:
                                doctor['available'] ? Colors.green : Colors.red,
                            size: 10,
                          ),
                          Text(
                            doctor['available'] ? " Online" : " Offline",
                            style: TextStyle(
                              color: doctor['available']
                                  ? Colors.green
                                  : Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatDetailScreen(doctor: doctor),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text("Chat"),
                  style: TextButton.styleFrom(foregroundColor: Colors.teal),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
