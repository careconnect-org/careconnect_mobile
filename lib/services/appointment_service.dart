import 'package:careconnect/models/appointment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'notification_service.dart';

class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  final String appointmentsCollection = 'appointments';

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
      await _notificationService.sendAppointmentCreatedNotification(
        appointment.id,
        appointment.patientName,
        _formatDateTime(appointment.dateTime),
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
      await _notificationService.sendAppointmentUpdatedNotification(
        appointment.id,
        appointment.patientName,
        _formatDateTime(appointment.dateTime),
      );
    } catch (e) {
      print('Error updating appointment: $e');
      rethrow;
    }
  }

  // Update appointment status
  Future<void> updateAppointmentStatus(
      String appointmentId, String newStatus) async {
    try {
      // Get the appointment
      DocumentSnapshot doc = await _firestore
          .collection(appointmentsCollection)
          .doc(appointmentId)
          .get();

      if (!doc.exists) {
        throw Exception('Appointment not found');
      }

      Appointment appointment =
          Appointment.fromJson(doc.data() as Map<String, dynamic>);

      // Update status
      Appointment updatedAppointment = appointment.copyWith(status: newStatus);

      // Save to Firestore
      await _firestore
          .collection(appointmentsCollection)
          .doc(appointmentId)
          .update({
        'status': newStatus,
      });

      // Send notification
      await _notificationService.sendAppointmentStatusChangedNotification(
        appointmentId,
        appointment.patientName,
        newStatus,
      );
    } catch (e) {
      print('Error updating appointment status: $e');
      rethrow;
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
      await _notificationService.sendAppointmentDeletedNotification(
        appointment.patientName,
        _formatDateTime(appointment.dateTime),
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
