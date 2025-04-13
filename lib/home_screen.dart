import 'package:flutter/material.dart';
import 'appointment_screen.dart'; 
import 'history_screen.dart'; 
import 'favorite_doctor_screen.dart';
import 'notification_screen.dart';
import 'profile_screen.dart'; 
import 'doctorscreen.dart'; 
import 'FoodsScreen.dart';
import 'HealthScreen.dart';
import 'SportsScreen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  int _currentIndex = 0;

  // List of screens for each BottomNavigationBar item
  final List<Widget> _screens = [
    HomeScreenContent(),  
    AppointmentScreen(),  
    MessageHistoryScreen(),      
    ProfileScreen(),      
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundImage: NetworkImage('assets/images/avatar.png'),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Good Morning 👋',
                style: TextStyle(fontSize: 14, color: Colors.grey)),
            Text('Andrew Ainsley',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => NotificationScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.favorite_border),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => MyFavoriteDoctorScreen()),
              );
            },
          ),
        ],
      ),
      body: _screens[_currentIndex], 
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Appointment',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
        currentIndex: _currentIndex,
        onTap: _onItemTapped, // Handle item taps
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}

class HomeScreenContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: Icon(Icons.search),
                suffixIcon: Icon(Icons.filter_list),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            SizedBox(height: 16),

            // Medical Checks Banner
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 40), // Adjust to make space for image
                      Text(
                        'Medical Checks!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Check your health condition regularly to minimize the incidence of disease in the future',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HealthScreen(),
              ),
            );
                        },
                        child: Text('Check Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 10, // Adjust to place the image slightly above
                  right: 0, // Adjust as needed
                  child: Opacity(
                    opacity: 0.3, // Adjust transparency level
                    child: Image.asset(
                      'assets/images/avatar.png',
                      width: 120,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Doctor Specialty Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Doctor Specialty',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                                   Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DoctorsPage(),
              ),
            );
                  },
                  child: Text('See All'),
                ),
              ],
            ),
            SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSpecialtyIcon(Icons.medical_services, 'General'),
                  _buildSpecialtyIcon(Icons.airline_seat_flat, 'Dentist'),
                  _buildSpecialtyIcon(Icons.remove_red_eye, 'Ophthal..'),
                  _buildSpecialtyIcon(Icons.restaurant, 'Nutrition..'),
                  _buildSpecialtyIcon(Icons.psychology, 'Neurolo..'),
                  _buildSpecialtyIcon(Icons.child_friendly, 'Pediatric'),
                  _buildSpecialtyIcon(Icons.radio, 'Radiolo..'),
                 _buildDoctorFilter('All', isSelected: true),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Top Doctors Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Categories',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    
                  },
                  child: Text('See All'),
                ),
              ],
            ),
            SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildDoctorFilter('All', isSelected: true),
                  _buildDoctorFilter('General'),
                  _buildDoctorFilter('Dentist'),
                  _buildDoctorFilter('Nutritionist'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialtyIcon(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: EdgeInsets.all(12),
            child: Icon(icon, color: Colors.blue),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorFilter(String label, {bool isSelected = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
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




