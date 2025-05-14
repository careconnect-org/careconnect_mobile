import 'package:careconnect/admin/admin_bottom_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../admin/appointment_admin_screen.dart'; // Add this import

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Channel IDs
  static const String _appointmentChannelId = 'appointment_channel';
  static const String _appointmentChannelName = 'Appointment Notifications';
  static const String _appointmentChannelDesc =
      'Notifications for appointment updates';

  // Notification IDs
  static const int _appointmentCreatedId = 1;
  static const int _appointmentUpdatedId = 2;
  static const int _appointmentStatusChangedId = 3;
  static const int _appointmentDeletedId = 4;

  // Global navigator key for navigation
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  Future<void> initialize() async {
    try {
      // Request notification permissions
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get FCM token
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('FCM Token: $token');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', token);
      }

      // Subscribe to general appointment notifications
      await _firebaseMessaging.subscribeToTopic('appointments');
      print('Subscribed to appointment notifications');
    } catch (e) {
      print('Error initializing notification service: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    try {
      // Android initialization
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Initialize settings
      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      // Initialize plugin
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (response.payload != null) {
            print('Notification tapped with payload: ${response.payload}');
            _handleNotificationTap(response.payload!);
          }
        },
      );

      // Create notification channel for Android
      await _createNotificationChannel();
    } catch (e) {
      print('Error initializing local notifications: $e');
    }
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _appointmentChannelId,
      _appointmentChannelName,
      description: _appointmentChannelDesc,
      importance: Importance.high,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Handle notification tap
  void _handleNotificationTap(String payload) {
    try {
      final data = json.decode(payload);
      print('Handling notification tap with data: $data');

      // Navigate based on notification type
      if (data.containsKey('appointmentId')) {
        _navigateToAppointmentDetail(data['appointmentId']);
      } else {
        _navigateToAppointments();
      }
    } catch (e) {
      print('Error parsing notification payload: $e');
    }
  }

  // Subscribe admin to admin-specific notifications
  Future<void> subscribeToAdminNotifications() async {
    try {
      await _firebaseMessaging.subscribeToTopic('admin');
      print('Subscribed to admin notifications');
    } catch (e) {
      print('Error subscribing to admin notifications: $e');
    }
  }

  // Send appointment status changed notification
  Future<void> sendAppointmentStatusChangedNotification(
      Map<String, dynamic> appointment, String newStatus,
      {bool sendToPatient = true, bool sendToDoctor = true}) async {
    final appointmentId = appointment['_id'];
    final patientId = _getPatientId(appointment);
    final doctorId = _getDoctorId(appointment);
    final String title = 'Appointment Status Updated';
    final String body = 'Your appointment has been updated to $newStatus';

    try {
      // Send to patient
      if (sendToPatient && patientId != null) {
        await _sendPushNotification(
          userId: patientId,
          title: title,
          body: body,
          payload: {
            'type': 'appointment_status',
            'appointmentId': appointmentId,
            'status': newStatus,
          },
        );
      }

      // Send to doctor
      if (sendToDoctor && doctorId != null) {
        await _sendPushNotification(
          userId: doctorId,
          title: title,
          body: body,
          payload: {
            'type': 'appointment_status',
            'appointmentId': appointmentId,
            'status': newStatus,
          },
        );
      }

      // Also show local notification
      await _showLocalNotification(
        id: 1,
        title: title,
        body: body,
        payload: {
          'type': 'appointment_status',
          'appointmentId': appointmentId,
          'status': newStatus,
        },
      );
    } catch (e) {
      print('Error sending status notification: $e');
    }
  }

  // Send new appointment notification
  Future<void> sendNewAppointmentNotification(Map<String, dynamic> appointment,
      {bool sendToPatient = true, bool sendToDoctor = true}) async {
    final appointmentId = appointment['_id'];
    final patientId = _getPatientId(appointment);
    final doctorId = _getDoctorId(appointment);
    final String title = 'New Appointment Created';
    final String body = 'A new appointment has been scheduled';

    try {
      print('Patient ID extracted: $patientId');
      print('Doctor ID extracted: $doctorId');

      // Send to patient
      if (sendToPatient && patientId != null) {
        print('Sending notification to patient: $patientId');
        await _sendPushNotification(
          userId: patientId,
          title: title,
          body: body,
          payload: {
            'type': 'new_appointment',
            'appointmentId': appointmentId,
          },
        );
      }

      // Send to doctor
      if (sendToDoctor && doctorId != null) {
        print('Sending notification to doctor: $doctorId');
        await _sendPushNotification(
          userId: doctorId,
          title: title,
          body: body,
          payload: {
            'type': 'new_appointment',
            'appointmentId': appointmentId,
          },
        );
      }

      // Also show local notification
      await _showLocalNotification(
        id: 2,
        title: title,
        body: body,
        payload: {
          'type': 'new_appointment',
          'appointmentId': appointmentId,
        },
      );
    } catch (e) {
      print('Error sending new appointment notification: $e');
    }
  }

  // For backward compatibility - supporting old method signatures
  Future<void> sendAppointmentCreatedNotification(dynamic appointment) async {
    Map<String, dynamic> appointmentData = {};

    try {
      if (appointment is Map) {
        appointment.forEach((key, value) {
          if (key is String) {
            appointmentData[key] = value;
          }
        });
      } else if (appointment != null) {
        try {
          appointmentData['_id'] = appointment.id?.toString() ?? '';
          appointmentData['patientName'] =
              appointment.patientName?.toString() ?? '';
          if (appointment.dateTime != null) {
            appointmentData['dateTime'] = appointment.dateTime;
          }
        } catch (e) {
          print('Error extracting appointment data: $e');
        }
      }

      await sendNewAppointmentNotification(
        appointmentData,
        sendToPatient: true,
        sendToDoctor: true,
      );
    } catch (e) {
      print('Error sending appointment created notification: $e');
    }
  }

  Future<void> sendAppointmentUpdatedNotification(dynamic appointment) async {
    Map<String, dynamic> appointmentData = {};

    try {
      if (appointment is Map) {
        appointment.forEach((key, value) {
          if (key is String) {
            appointmentData[key] = value;
          }
        });
      } else if (appointment != null) {
        try {
          appointmentData['_id'] = appointment.id?.toString() ?? '';
          appointmentData['patientName'] =
              appointment.patientName?.toString() ?? '';
          if (appointment.dateTime != null) {
            appointmentData['dateTime'] = appointment.dateTime;
          }
        } catch (e) {
          print('Error extracting appointment data: $e');
        }
      }

      await _showLocalNotification(
        id: 3,
        title: 'Appointment Updated',
        body: 'An appointment has been updated',
        payload: {
          'type': 'appointment_update',
          'appointmentId': appointmentData['_id'] ?? '',
        },
      );
    } catch (e) {
      print('Error sending appointment updated notification: $e');
    }
  }

  // Send deleted appointment notification
  Future<void> sendDeletedAppointmentNotification(
      Map<String, dynamic> appointment,
      {bool sendToPatient = true,
      bool sendToDoctor = true}) async {
    final patientId = _getPatientId(appointment);
    final doctorId = _getDoctorId(appointment);
    final String title = 'Appointment Cancelled';
    final String body = 'An appointment has been cancelled';

    try {
      // Send to patient
      if (sendToPatient && patientId != null) {
        await _sendPushNotification(
          userId: patientId,
          title: title,
          body: body,
          payload: {
            'type': 'deleted_appointment',
          },
        );
      }

      // Send to doctor
      if (sendToDoctor && doctorId != null) {
        await _sendPushNotification(
          userId: doctorId,
          title: title,
          body: body,
          payload: {
            'type': 'deleted_appointment',
          },
        );
      }

      // Also show local notification
      await _showLocalNotification(
        id: 3,
        title: title,
        body: body,
        payload: {
          'type': 'deleted_appointment',
        },
      );
    } catch (e) {
      print('Error sending deleted appointment notification: $e');
    }
  }

  // Helper to extract patient ID from appointment - more robust implementation
  String? _getPatientId(Map<String, dynamic> appointment) {
    try {
      print(
          'Extracting patient ID from appointment: ${json.encode(appointment)}');

      // Check nested patient object
      if (appointment['patient'] is Map) {
        var patient = appointment['patient'];
        print('Found nested patient object: ${json.encode(patient)}');

        // Try various common ID field names
        for (var idField in ['_id', 'id', 'userId', 'patientId']) {
          if (patient.containsKey(idField) && patient[idField] != null) {
            print('Found patient ID in field "$idField": ${patient[idField]}');
            return patient[idField]?.toString();
          }
        }
      }

      // Check direct ID fields
      for (var idField in ['patientId', 'patient_id', 'userId', 'user_id']) {
        if (appointment.containsKey(idField) && appointment[idField] != null) {
          print(
              'Found patient ID in appointment field "$idField": ${appointment[idField]}');
          return appointment[idField]?.toString();
        }
      }

      // Try to use the entire patient string if it's not a map
      if (appointment.containsKey('patient') &&
          appointment['patient'] != null &&
          appointment['patient'] is! Map) {
        print('Using patient as identifier: ${appointment['patient']}');
        return appointment['patient']?.toString();
      }

      print('Could not find patient ID in appointment data');
    } catch (e) {
      print('Error getting patient ID: $e');
    }
    return null;
  }

  // Helper to extract doctor ID from appointment
  String? _getDoctorId(Map<String, dynamic> appointment) {
    try {
      if (appointment['doctor'] is Map) {
        var doctor = appointment['doctor'];
        if (doctor.containsKey('_id')) {
          return doctor['_id']?.toString();
        } else if (doctor.containsKey('id')) {
          return doctor['id']?.toString();
        } else if (doctor.containsKey('userId')) {
          return doctor['userId']?.toString();
        }
      } else if (appointment['doctorId'] != null) {
        return appointment['doctorId']?.toString();
      } else if (appointment['doctor'] != null &&
          appointment['doctor'] is! Map) {
        return appointment['doctor']?.toString();
      }
    } catch (e) {
      print('Error getting doctor ID: $e');
    }
    return null;
  }

  // Send push notification to a specific user
  Future<void> _sendPushNotification({
    required String userId,
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {
    try {
      print('Preparing to send push notification to user ID: $userId');
      print('Title: $title');
      print('Body: $body');
      print('Payload: $payload');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        print('Cannot send notification: No auth token available');
        return;
      }

      // Prepare notification data
      final notificationData = {
        'userId': userId,
        'title': title,
        'body': body,
        'data': payload,
      };

      print('Sending notification data: ${json.encode(notificationData)}');

      final response = await http.post(
        Uri.parse(
            'https://careconnect-api-v2kw.onrender.com/api/notifications/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(notificationData),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('Successfully sent push notification to user $userId');
        print('Response: ${response.body}');
      } else {
        print(
            'Failed to send push notification. Status: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('Error sending push notification: $e');
    }
  }

  // Show a local notification on this device
  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'careconnect_appointments',
        'Appointment Notifications',
        channelDescription: 'Notifications for appointment updates',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        platformChannelSpecifics,
        payload: json.encode(payload),
      );

      print('Local notification shown: $title');
    } catch (e) {
      print('Error showing local notification: $e');
    }
  }

  // Navigation helpers
  void _navigateToAppointmentDetail(String appointmentId) {
    if (navigatorKey.currentState != null) {
      // Save the appointment ID to show
      _saveAppointmentToShow(appointmentId);
      // Navigate to appointments screen
      _navigateToAppointments();
    }
  }

  void _navigateToAppointments() {
    if (navigatorKey.currentState != null) {
      // Navigate to AdminBottomScreen with index 0 (first tab)
      navigatorKey.currentState!.push(
        MaterialPageRoute(
          builder: (context) => const AdminBottomScreen(initialIndex: 0),
        ),
      );
    }
  }

  // Save appointment ID to show in shared preferences
  Future<void> _saveAppointmentToShow(String appointmentId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('show_appointment_id', appointmentId);
  }

  // Test method for debugging
  Future<void> sendTestNotification(String userId, String message) async {
    await _sendPushNotification(
      userId: userId,
      title: 'Test Notification',
      body: message,
      payload: {'type': 'test'},
    );

    await _showLocalNotification(
      id: 999,
      title: 'Test Notification',
      body: message,
      payload: {'type': 'test'},
    );
  }

  // Test method specifically for patients
  Future<void> sendTestNotificationToPatient(String patientId) async {
    try {
      print('Sending test notification to patient ID: $patientId');

      await _sendPushNotification(
        userId: patientId,
        title: 'Test Patient Notification',
        body: 'This is a test notification for a patient from Care Connect',
        payload: {
          'type': 'test_notification',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // Also show a local notification
      await _showLocalNotification(
        id: 999,
        title: 'Test Patient Notification Sent',
        body: 'Attempted to send notification to patient ID: $patientId',
        payload: {'type': 'test_notification'},
      );

      print('Test patient notification process completed');
    } catch (e) {
      print('Error sending test notification to patient: $e');
    }
  }
}
