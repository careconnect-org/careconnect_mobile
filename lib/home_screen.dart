import 'package:careconnect/FoodsScreen.dart';
import 'package:careconnect/SportsScreen.dart';
import 'package:flutter/material.dart';
import 'favorite_doctor_screen.dart';
import 'notification_screen.dart';
import 'package:careconnect/doctorscreen.dart';
import 'HealthScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'screens/chat_list_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? userData;
  bool _isLoading = true;
  int notificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    loadNotificationCount();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');

      if (userDataString != null) {
        setState(() {
          userData = jsonDecode(userDataString) as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> loadNotificationCount() async {
    final count = await fetchNotificationCount();
    setState(() {
      notificationCount = count;
    });
  }

  Future<int> fetchNotificationCount() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userId = prefs.getString('user_id');
    if (token == null || userId == null) return 0;

    final response = await http.get(
      Uri.parse(
          'https://careconnect-api-v2kw.onrender.com/api/notify/get/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> notifications = json.decode(response.body);
      // Count unseen notifications (assuming 'seen' is a boolean field)
      return notifications.where((n) => n['seen'] == false).length;
    }
    return 0;
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundImage: userData?['image'] != null
                ? NetworkImage(userData!['image'])
                : const AssetImage('assets/images/avatar.png') as ImageProvider,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_getGreeting()} 👋',
                style: const TextStyle(fontSize: 14, color: Colors.white)),
            Text(
                userData != null
                    ? '${userData!['firstName']} ${userData!['lastName']}'
                    : 'Loading...',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => NotificationScreen()),
                  );
                },
              ),
              if (notificationCount > 0)
                Positioned(
                  right: 11,
                  top: 11,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$notificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.message_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ChatListScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => MyFavoriteDoctorScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              Container(
                height: 60,
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    hintText: 'Search by specialty',
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: Icon(Icons.filter_list),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                  isExpanded: true,
                  menuMaxHeight: 300,
                  items: [
                    'All Specialties',
                    'General Practitioner',
                    'Cardiologist',
                    'Ophthalmologist',
                    'Nutritionist',
                    'Neurologist',
                    'Pediatrician',
                    'Radiologist',
                    'Dermatologist',
                    'Orthopedist',
                    'Gynecologist',
                    'ENT Specialist',
                    'Psychiatrist',
                    'Dentist',
                  ].map((String specialty) {
                    return DropdownMenuItem<String>(
                      value: specialty,
                      child: Text(
                        specialty,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      // Navigate to doctors page with selected specialty
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DoctorsPage(selectedSpecialty: newValue),
                        ),
                      );
                    }
                  },
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
                        SizedBox(height: 40),
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
              SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount =
                      (constraints.maxWidth ~/ 80).clamp(2, 4); // responsive
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1,
                    children: [
                      _buildSpecialtyIcon(Icons.medical_services, 'General'),
                      _buildSpecialtyIcon(Icons.airline_seat_flat, 'Cardiolo..'),
                      _buildSpecialtyIcon(Icons.remove_red_eye, 'Ophthal..'),
                      _buildSpecialtyIcon(Icons.restaurant, 'Nutritio..'),
                      _buildSpecialtyIcon(Icons.psychology, 'Neurolo..'),
                      _buildSpecialtyIcon(Icons.child_friendly, 'Pediatr..'),
                      _buildSpecialtyIcon(Icons.radio, 'Radiolo..'),
                    ],
                  );
                },
              ),

  // Add spacing before categories
              SizedBox(height: 24),

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
                ],
              ),
              SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount =
                      (constraints.maxWidth ~/ 100).clamp(2, 4); // responsive
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.5,
                    children: [
                      _buildCategoryButton(context, 'Foods', FoodsScreen(),
                          emoji: '🥦'),
                      _buildCategoryButton(context, 'Sports', SportsScreen(),
                          emoji: '🏃‍♂️'),
                      _buildCategoryButton(context, 'Health', HealthScreen(),
                          emoji: '💊'),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialtyIcon(IconData icon, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: EdgeInsets.all(4),
          child: Icon(icon, color: Colors.blue),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCategoryButton(BuildContext context, String label, Widget screen,
      {required String emoji}) {
    return InkWell(
      onTap: () {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => screen));
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color.fromARGB(255, 25, 117, 183),
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                emoji,
                style: TextStyle(fontSize: 20),
              ),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: const Color.fromARGB(255, 25, 117, 183),
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
