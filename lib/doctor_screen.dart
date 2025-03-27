import 'package:flutter/material.dart';

class TopDoctorScreen extends StatelessWidget {
  final List<Map<String, String>> doctors = [
    {
      'name': 'Dr. Randy Wigham',
      'specialty': 'Cardiologist | The Valley Hospital',
      'rating': '4.4',
      'reviews': '14,579',
      'image': 'assets/doctors/randy.png'
    },
    {
      'name': 'Dr. Jenny Watson',
      'specialty': 'Immunologist | Child Hospital',
      'rating': '4.4',
      'reviews': '14,582',
      'image': 'assets/doctors/jenny.png'
    },
    {
      'name': 'Dr. Raul Zirkind',
      'specialty': 'Neurologist | Practis Hospital',
      'rating': '4.8',
      'reviews': '16,502',
      'image': 'assets/doctors/raul.png'
    },
    {
      'name': 'Dr. Elijah Baranick',
      'specialty': 'Allergist | PK Medical Center',
      'rating': '4.6',
      'reviews': '12,587',
      'image': 'assets/doctors/elijah.png'
    },
    {
      'name': 'Dr. Stephen Shute',
      'specialty': 'Cardiologist | Alta Hospital',
      'rating': '4.4',
      'reviews': '15,205',
      'image': 'assets/doctors/stephen.png'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Top Doctor'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('All', true),
                _buildFilterChip('General', false),
                _buildFilterChip('Dentist', false),
                _buildFilterChip('Nutritionist', false),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: doctors.length,
              itemBuilder: (context, index) {
                final doctor = doctors[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: AssetImage(doctor['image']!),
                    radius: 30,
                  ),
                  title: Text(
                    doctor['name']!,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doctor['specialty']!),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.yellow, size: 16),
                          SizedBox(width: 4),
                          Text('${doctor['rating']} (${doctor['reviews']} reviews)'),
                        ],
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.favorite_border),
                    onPressed: () {},
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        onPressed: () {},
        child: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.blue : Colors.white,
          foregroundColor: isSelected ? Colors.white : Colors.blue,
          side: BorderSide(color: Colors.blue),
        ),
      ),
    );
  }
}