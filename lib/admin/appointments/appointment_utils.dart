import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/notification_service.dart';

class AppointmentUtils {
  // Show confirmation dialog for deleting an appointment
  static Future<bool?> showDeleteConfirmationDialog(
      BuildContext context, String appointmentId) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Appointment'),
          content: const Text(
              'Are you sure you want to delete this appointment? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final success =
                    await _deleteAppointment(context, appointmentId);
                Navigator.of(context).pop(success);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // Delete an appointment
  static Future<bool> _deleteAppointment(
      BuildContext context, String appointmentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication token missing. Please login again.'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }

      // First, get the appointment details for notification
      final getResponse = await http.get(
        Uri.parse(
            'https://careconnect-api-v2kw.onrender.com/api/appointment/$appointmentId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      Map<String, dynamic>? appointmentData;
      if (getResponse.statusCode == 200) {
        final responseBody = json.decode(getResponse.body);
        if (responseBody is Map && responseBody.containsKey('appointment')) {
          appointmentData = responseBody['appointment'];
        } else if (responseBody is Map && responseBody.containsKey('data')) {
          appointmentData = responseBody['data'];
        } else {
          appointmentData = responseBody;
        }
      }

      // Delete the appointment
      final response = await http.delete(
        Uri.parse(
            'https://careconnect-api-v2kw.onrender.com/api/appointment/$appointmentId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Send notification about deleted appointment
        if (appointmentData != null) {
          await NotificationService().sendDeletedAppointmentNotification(
            appointmentData,
            sendToPatient: true,
            sendToDoctor: true,
          );
        }

        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Failed to delete appointment: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  // Add this method for updating appointment status
  static Future<bool> updateAppointmentStatus(
      BuildContext context, String id, String newStatus) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication token missing. Please login again.'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }

      // First, get the appointment details for notification
      final getResponse = await http.get(
        Uri.parse(
            'https://careconnect-api-v2kw.onrender.com/api/appointment/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (getResponse.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to get appointment details'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }

      final appointmentData = json.decode(getResponse.body);
      Map<String, dynamic> appointment;

      // Handle different response formats
      if (appointmentData is Map &&
          appointmentData.containsKey('appointment')) {
        appointment = appointmentData['appointment'];
      } else if (appointmentData is Map &&
          appointmentData.containsKey('data')) {
        appointment = appointmentData['data'];
      } else {
        appointment = appointmentData;
      }

      // Now update the status
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

        // Send notification for status change
        await NotificationService().sendAppointmentStatusChangedNotification(
            appointment, newStatus,
            sendToPatient: true, sendToDoctor: true);

        return true;
      } else {
        final responseData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Failed to update status'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  // Add a test notification method that can be used for debugging
  static Future<void> testPatientNotification(
      BuildContext context, String patientId) async {
    try {
      await NotificationService().sendTestNotificationToPatient(patientId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test notification sent to patient ID: $patientId'),
          backgroundColor: Colors.blue,
          action: SnackBarAction(
            label: 'DISMISS',
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending test notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
