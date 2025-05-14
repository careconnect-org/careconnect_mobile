import 'package:careconnect/models/appointment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';

class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  final String appointmentsCollection = 'appointments';
  static const String baseUrl = 'https://careconnect-api-v2kw.onrender.com/api';

  // Create a new appointment
  Future<void> createAppointment(Appointment appointment) async {
    try {
      // Save appointment to Firestore
      await _firestore
          .collection(appointmentsCollection)
          .doc(appointment.id)
          .set(
            appointment.toJson(),
          );

      // Send notification
      await _notificationService.sendNewAppointmentNotification(
        appointment.toJson(),
      );
    } catch (e) {
      print('Error creating appointment: $e');
      rethrow;
    }
  }

  // Update an existing appointment
  Future<void> updateAppointment(Appointment appointment) async {
    try {
      // Update appointment in Firestore
      await _firestore
          .collection(appointmentsCollection)
          .doc(appointment.id)
          .update(
            appointment.toJson(),
          );

      // Send notification
      await _notificationService.sendAppointmentStatusChangedNotification(
        appointment.toJson(),
        appointment.status,
      );
    } catch (e) {
      print('Error updating appointment: $e');
      rethrow;
    }
  }

  // Update appointment status
  Future<Map<String, dynamic>> updateAppointmentStatus(String appointmentId, String newStatus) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      print('Updating appointment status: $appointmentId to $newStatus');
      print('Using token: ${token.substring(0, 10)}...');

      final response = await http.put(
        Uri.parse('$baseUrl/appointment/status/$appointmentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'status': newStatus,
        }),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final updatedAppointment = json.decode(response.body);
        // Send notification about status change
        await _notificationService.sendAppointmentStatusChangedNotification(
          updatedAppointment,
          newStatus,
        );
        return updatedAppointment;
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Failed to update appointment status';
        print('Error updating status: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Exception in updateAppointmentStatus: $e');
      throw Exception('Error updating appointment status: $e');
    }
  }

  // Delete an appointment
  Future<void> deleteAppointment(String appointmentId) async {
    try {
      // Get the appointment before deleting
      DocumentSnapshot doc = await _firestore
          .collection(appointmentsCollection)
          .doc(appointmentId)
          .get();

      if (!doc.exists) {
        throw Exception('Appointment not found');
      }

      Appointment appointment =
          Appointment.fromJson(doc.data() as Map<String, dynamic>);

      // Delete from Firestore
      await _firestore
          .collection(appointmentsCollection)
          .doc(appointmentId)
          .delete();

      // Send notification
      await _notificationService.sendAppointmentStatusChangedNotification(
        appointment.toJson(),
        'Cancelled',
      );
    } catch (e) {
      print('Error deleting appointment: $e');
      rethrow;
    }
  }

  // Get all appointments
  Stream<List<Appointment>> getAppointments() {
    return _firestore
        .collection(appointmentsCollection)
        .orderBy('dateTime')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Appointment.fromJson(doc.data());
      }).toList();
    });
  }

  // Format DateTime for display
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
