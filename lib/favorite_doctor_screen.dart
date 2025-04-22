import 'package:flutter/material.dart';

class MyFavoriteDoctorScreen extends StatefulWidget {
  @override
  _MyFavoriteDoctorScreenState createState() => _MyFavoriteDoctorScreenState();
}

class _MyFavoriteDoctorScreenState extends State<MyFavoriteDoctorScreen> {
  final List<Map<String, String>> doctors = [
    {
      'name': 'Dr. Travis Westaby',
      'specialty': 'Cardiologist | Alta Hospital',
      'rating': '4.5',
      'reviews': '15,279',
      'image': 'assets/doctors/travis.png'
    },
    {
      'name': 'Dr. Nathaniel Valle',
      'specialty': 'Cardiologist | BMI Hospital',
      'rating': '4.6',
      'reviews': '10,857',
      'image': 'assets/doctors/nathaniel.png'
    },
    {
      'name': 'Dr. Beckett Calger',
      'specialty': 'Cardiologist | Venia Hospital',
      'rating': '4.4',
      'reviews': '14,142',
      'image': 'assets/doctors/beckett.png'
    },
    {
      'name': 'Dr. Jada Smoky',
      'specialty': 'Cardiologist | Alta Hospital',
      'rating': '4.6',
      'reviews': '15,804',
      'image': 'assets/doctors/jada.png'
    },
    {
      'name': 'Dr. Bernard Bliss',
      'specialty': 'Cardiologist | The Valley Hospital',
      'rating': '4.4',
      'reviews': '12,579',
      'image': 'assets/doctors/bernard.png'
    },
  ];

  void _showRemoveDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove from Favorites?'),
        content: Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage(doctors[index]['image']!),
              radius: 30,
            ),
            SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctors[index]['name']!,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  doctors[index]['specialty']!,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                doctors.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: Text('Yes, Remove'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        iconTheme: IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title:
            Text('My Favorite Doctor', style: TextStyle(color: Colors.white)),
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
                          Text(
                              '${doctor['rating']} (${doctor['reviews']} reviews)'),
                        ],
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.favorite, color: Colors.blue),
                    onPressed: () => _showRemoveDialog(index),
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
