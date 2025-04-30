import 'package:flutter/material.dart';

import 'package:careconnect/admin/appointments/upcoming_appointments_screen.dart';
import 'package:careconnect/admin/appointments/completed_appointments_screen.dart';
import 'package:careconnect/admin/appointments/cancelled_appointments_screen.dart';

class AppointmentadminScreen extends StatefulWidget {
  const AppointmentadminScreen({super.key});

  @override
  State<AppointmentadminScreen> createState() => _AppointmentadminScreenState();
}

class _AppointmentadminScreenState extends State<AppointmentadminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        backgroundColor: Colors.blue,
        title: const Text("Appointments Management",
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
        bottom: TabBar(
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          controller: _tabController,
          tabs: const [
            Tab(text: "Upcoming"),
            Tab(text: "Complethhhed"),
            Tab(text: "Cancelled"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          // Separate screens for each tab
          UpcomingAppointmentsScreen(),
          CompletedAppointmentsScreen(),
          CancelledAppointmentsScreen(),
        ],
      ),
    );
  }
}
