import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'appointment_utils.dart';
import 'appointment_detail_screen.dart';
import 'services/notification_service.dart';
import 'package:careconnect/services/local_storage_service.dart';

class CompletedAppointmentsScreen extends StatefulWidget {
  @override
  _CompletedAppointmentsScreenState createState() =>
      _CompletedAppointmentsScreenState();
}

class _CompletedAppointmentsScreenState
    extends State<CompletedAppointmentsScreen> {
  List<dynamic> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUpcomingAppointments();
  }

  Future<void> fetchUpcomingAppointments() async {
    setState(() {
      _isLoading = true;
    });

    final token = await LocalStorageService.getAuthToken();
    if (token == null) return;

    var response = await http.get(
      Uri.parse('https://yourapiurl.com/appointments/upcoming'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _appointments = json.decode(response.body);
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      // Handle error
    }
  }

  // Show status update options
  void _showStatusUpdateOptions(Map<String, dynamic> appointment) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Update Appointment Status',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.upcoming, color: Colors.blue),
                title: const Text('Upcoming'),
                onTap: () async {
                  Navigator.pop(context);
                  bool success = await AppointmentUtils.updateAppointmentStatus(
                      context, appointment['_id'], 'Upcoming');
                  if (success) {
                    // Send notification for status change
                    await NotificationService().sendAppointmentStatusChangedNotification(
                      appointment, 'Upcoming');
                  }
                  fetchUpcomingAppointments();
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Completed'),
                onTap: () async {
                  Navigator.pop(context);
                  bool success = await AppointmentUtils.updateAppointmentStatus(
                      context, appointment['_id'], 'Completed');
                  if (success) {
                    // Send notification for status change
                    await NotificationService().sendAppointmentStatusChangedNotification(
                      appointment, 'Completed');
                  }
                  fetchUpcomingAppointments();
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: const Text('Cancelled'),
                onTap: () async {
                  Navigator.pop(context);
                  bool success = await AppointmentUtils.updateAppointmentStatus(
                      context, appointment['_id'], 'Cancelled');
                  if (success) {
                    // Send notification for status change
                    await NotificationService().sendAppointmentStatusChangedNotification(
                      appointment, 'Cancelled');
                  }
                  fetchUpcomingAppointments();
                },
              ),
              ListTile(
                leading: const Icon(Icons.pending, color: Colors.orange),
                title: const Text('Pending'),
                onTap: () async {
                  Navigator.pop(context);
                  bool success = await AppointmentUtils.updateAppointmentStatus(
                      context, appointment['_id'], 'Pending');
                  if (success) {
                    // Send notification for status change
                    await NotificationService().sendAppointmentStatusChangedNotification(
                      appointment, 'Pending');
                  }
                  fetchUpcomingAppointments();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Appointments'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _appointments.length,
              itemBuilder: (context, index) {
                final appointment = _appointments[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 15),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(15),
                    title: Text(appointment['title']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Date: ${DateFormat.yMMMd().format(DateTime.parse(appointment['date']))}'),
                        Text('Time: ${DateFormat.jm().format(DateTime.parse(appointment['time']))}'),
                        Text('Status: ${appointment['status']}'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.more_vert),
                      onPressed: () {
                        _showStatusUpdateOptions(appointment);
                      },
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AppointmentDetailScreen(appointmentId: appointment['_id']),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
