import 'package:flutter/material.dart';

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<AppointmentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, String>> upcomingAppointments = [
    {
      'doctor': 'Dr. Ken Kennedy',
      'type': 'Voice Call',
      'status': 'Upcoming',
      'date': 'Apr 15, 2025',
      'time': '10:00 AM'
    },
  ];

  final List<Map<String, String>> completedAppointments = [
    {
      'doctor': 'Dr. Aidan Allende',
      'type': 'Video Call',
      'status': 'Completed',
      'date': 'Dec 14, 2022',
      'time': '15:00 PM'
    },
    {
      'doctor': 'Dr. Iker Holl',
      'type': 'Messaging',
      'status': 'Completed',
      'date': 'Nov 22, 2022',
      'time': '09:00 AM'
    },
    {
      'doctor': 'Dr. Jada Srnsky',
      'type': 'Voice Call',
      'status': 'Completed',
      'date': 'Nov 06, 2022',
      'time': '18:00 PM'
    },
  ];

  final List<Map<String, String>> cancelledAppointments = [
    {
      'doctor': 'Dr. Iris Smith',
      'type': 'Video Call',
      'status': 'Cancelled',
      'date': 'Apr 12, 2025',
      'time': '13:00 PM'
    },
  ];

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);
    super.initState();
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

  Widget _buildAppointmentCard(Map<String, String> appointment, {bool showActions = false}) {
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
              appointment['doctor']!,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                _getTypeIcon(appointment['type']!),
                const SizedBox(width: 6),
                Text(appointment['type']!),
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
      appBar: AppBar(
        title: const Text("My Appointments"),
        centerTitle: true,
        backgroundColor: const Color(0xFFF7F7F7),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Upcoming"),
            Tab(text: "Completed"),
            Tab(text: "Cancelled"),
          ],
        ),
      ),
      body: TabBarView(
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
