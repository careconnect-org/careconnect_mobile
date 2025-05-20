import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/notification_service.dart';
import 'package:careconnect/services/local_storage_service.dart';

class AppointmentUtils {
  // ...existing code...

  // Update appointment status using the dedicated status endpoint
  static Future<bool> updateAppointmentStatus(
      BuildContext context, String id, String newStatus) async {
    final token = await LocalStorageService.getAuthToken();
    if (token == null) return false;

    try {
      // First, get the appointment details
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
      if (appointmentData is Map && appointmentData.containsKey('appointment')) {
        appointment = appointmentData['appointment'];
      } else if (appointmentData is Map && appointmentData.containsKey('data')) {
        appointment = appointmentData['data'];
      } else {
        appointment = appointmentData;
      }

      // Then update status
      final updateResponse = await http.put(
        Uri.parse(
            'https://careconnect-api-v2kw.onrender.com/api/appointment/status/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': newStatus}),
      );

      if (updateResponse.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment status updated to $newStatus'),
            backgroundColor: Colors.green,
          ),
        );

        // Send notification for status change
        await NotificationService().sendAppointmentStatusChangedNotification(
          appointment, newStatus);

        return true;
      } else {
        final responseData = json.decode(updateResponse.body);
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

  // Delete appointment
  static Future<bool> deleteAppointment(BuildContext context, String id) async {
    final token = await LocalStorageService.getAuthToken();
    if (token == null) return false;

    try {
      // First, get the appointment details
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
      if (appointmentData is Map && appointmentData.containsKey('appointment')) {
        appointment = appointmentData['appointment'];
      } else if (appointmentData is Map && appointmentData.containsKey('data')) {
        appointment = appointmentData['data'];
      } else {
        appointment = appointmentData;
      }

      // Then delete the appointment
      final response = await http.delete(
        Uri.parse(
            'https://careconnect-api-v2kw.onrender.com/api/appointment/delete/$id'),
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

        // Send notification for deletion
        await NotificationService().sendAppointmentDeletedNotification(appointment);
        return true;
      } else {
        final responseData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(responseData['message'] ?? 'Failed to delete appointment'),
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

  // ...existing code...
}
```