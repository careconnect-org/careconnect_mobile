import 'package:careconnect/admin/appointment_admin_screen.dart';
import 'package:careconnect/admin/admin_health_recommendation_screen.dart';
import 'package:careconnect/history_screen.dart';
import 'package:careconnect/profile_screen.dart';
import 'package:flutter/material.dart';

class AdminBottomScreen extends StatefulWidget {
  final int initialIndex;

  const AdminBottomScreen({
    Key? key,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<AdminBottomScreen> createState() => _AdminBottomScreenState();
}

class _AdminBottomScreenState extends State<AdminBottomScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  final List<Widget> _screens = [
    AppointmentadminScreen(),
    AdminHealthRecommendationScreen(),
    MessageHistoryScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    if (index >= 0 && index < _screens.length) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Appointment',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: 'Recommendations',
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
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
