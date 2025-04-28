import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<AppointmentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> upcomingAppointments = [];
  List<Map<String, dynamic>> completedAppointments = [];
  List<Map<String, dynamic>> cancelledAppointments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchAppointments();
  }

  Future<void> fetchAppointments() async {
    setState(() { isLoading = true; });
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    final response = await http.get(
      Uri.parse('https://careconnect-api-v2kw.onrender.com/api/appointment/all'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      upcomingAppointments = [];
      completedAppointments = [];
      cancelledAppointments = [];
      for (var appt in data) {
        switch (appt['status']) {
          case 'Upcoming':
            upcomingAppointments.add(appt);
            break;
          case 'Completed':
            completedAppointments.add(appt);
            break;
          case 'Cancelled':
            cancelledAppointments.add(appt);
            break;
        }
      }
    }
    setState(() { isLoading = false; });
  }

  Icon _getTypeIcon(String type) {
    switch (type) {
      case 'Video Call':
        return const Icon(Icons.video_call, color: Colors.blue);
      case 'Voice Call':
        return const Icon(Icons.call, color: Colors.purple);
      case 'Messaging':
        return const Icon(Icons.message, color: Colors.orange);
      default:
        return const Icon(Icons.event_note, color: Colors.grey);
    }
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment, {bool showActions = false}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appointment['doctor']!.toString(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                _getTypeIcon(appointment['type']!.toString()),
                const SizedBox(width: 6),
                Text(appointment['type']!.toString()),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${appointment['date']} | ${appointment['time']}',
              style: const TextStyle(color: Colors.grey),
            ),
            if (showActions) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.replay),
                    label: const Text("Book Again"),
                    style: TextButton.styleFrom(foregroundColor: Colors.green),
                  ),
                  const SizedBox(width: 10),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.delete_outline),
                    label: const Text("Delete"),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(automaticallyImplyLeading: false,
        backgroundColor: Colors.blue,
        title: const Text("My Appointments", style: TextStyle(color: Colors.white),),
        centerTitle: true,
        bottom: TabBar(
          indicatorColor: Colors.blue,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          controller: _tabController,
          tabs: const [
            Tab(text: "Upcoming"),
            Tab(text: "Completed"),
            Tab(text: "Cancelled"),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          // Upcoming
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: upcomingAppointments.length,
              itemBuilder: (context, index) {
                return _buildAppointmentCard(upcomingAppointments[index]);
              },
            ),
          ),

          // Completed
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: completedAppointments.length,
              itemBuilder: (context, index) {
                return _buildAppointmentCard(
                  completedAppointments[index],
                  showActions: true,
                );
              },
            ),
          ),

          // Cancelled
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: cancelledAppointments.length,
              itemBuilder: (context, index) {
                return _buildAppointmentCard(cancelledAppointments[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
