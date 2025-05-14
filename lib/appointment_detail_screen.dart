import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// import 'appointment_utils.dart';
import 'appointment_form.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/notification_service.dart';

class AppointmentDetailScreen extends StatefulWidget {
  final String appointmentId;
  final Map<String, dynamic> appointmentData;
  final Function onAppointmentUpdated;

  AppointmentDetailScreen({
    required this.appointmentId,
    required this.appointmentData,
    required this.onAppointmentUpdated,
  });

  @override
  _AppointmentDetailScreenState createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  late Map<String, dynamic> appointmentData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    appointmentData = widget.appointmentData;
  }

  // Update appointment status using the dedicated status endpoint
  Future<void> _updateAppointmentStatus(String id, String newStatus) async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    try {
      final response = await http.put(
        Uri.parse(
            'https://careconnect-api-v2kw.onrender.com/api/appointment/status/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': newStatus}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment status updated to $newStatus'),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          appointmentData['status'] = newStatus;
        });

        // Send notification for status change
        await NotificationService().sendAppointmentStatusChangedNotification(
          appointmentData, newStatus);

        widget.onAppointmentUpdated();
      } else {
        final responseData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Failed to update status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Appointment Details'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Appointment ID: ${widget.appointmentId}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.0),
              Text('Date: ${DateFormat.yMMMd().format(DateTime.parse(appointmentData['date']))}'),
              Text('Time: ${appointmentData['time']}'),
              Text('Status: ${appointmentData['status']}'),
              SizedBox(height: 16.0),
              Text(
                'Description',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.0),
              Text(appointmentData['description'] ?? 'No description'),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  // Navigate to appointment form with existing data
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => AppointmentForm(
                      appointmentId: widget.appointmentId,
                      initialData: appointmentData,
                      onSave: (updatedData) {
                        setState(() {
                          appointmentData = updatedData;
                        });
                        widget.onAppointmentUpdated();
                      },
                    ),
                  ));
                },
                child: Text('Edit Appointment'),
              ),
              SizedBox(height: 16.0),
              Text(
                'Update Status',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.0),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => _updateAppointmentStatus(widget.appointmentId, 'confirmed'),
                    child: Text('Confirm'),
                  ),
                  SizedBox(width: 8.0),
                  ElevatedButton(
                    onPressed: () => _updateAppointmentStatus(widget.appointmentId, 'canceled'),
                    child: Text('Cancel'),
                  ),
                ],
              ),
              if (_isLoading) ...[
                SizedBox(height: 16.0),
                Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
