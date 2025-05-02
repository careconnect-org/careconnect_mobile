import 'package:careconnect/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/notification_service.dart';
import 'dart:convert';
import 'firebase_options.dart';
import 'letsign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/sports_crud_screen.dart';
import 'screens/food_crud_screen.dart';

// Use the global navigator key from the NotificationService
final GlobalKey<NavigatorState> navigatorKey = NotificationService.navigatorKey;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with a timeout before showing the app
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 3));
  } catch (e) {
    print('Firebase initialization issue: $e');
    // Continue without Firebase
  }

  // Start the app immediately
  runApp(const MyApp());

  // Perform additional non-critical initialization after the app has launched
  _completeInitialization();
}

Future<void> _completeInitialization() async {
  try {
    // Initialize notification service
    await NotificationService().initialize();

    // Non-blocking user role check
    _checkUserRoleAndSubscribe();
  } catch (e) {
    print('Error during additional initialization: $e');
  }
}

Future<void> _checkUserRoleAndSubscribe() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      final userInfo = Map<String, dynamic>.from(json.decode(userData));
      final userRole = userInfo['role']?.toString().toLowerCase();

      if (userRole == 'admin') {
        // Subscribe to admin topic for notifications
        await NotificationService().subscribeToAdminNotifications();
      }
    }
  } catch (e) {
    print('Error checking user role: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Care Connect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: WelcomeScreen(),
      routes: {
        '/appointments': (context) => const AppointmentsNavigator(),
        '/sports-crud': (context) => const SportsCrudScreen(),
        '/food-crud': (context) => const FoodCrudScreen(),
      },
    );
  }
}

// Simple navigator for appointments
class AppointmentsNavigator extends StatelessWidget {
  const AppointmentsNavigator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // This would navigate to your appointments tab in your actual app
    // For now, just showing a placeholder
    return Scaffold(
      appBar: AppBar(title: const Text('Appointments')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            // Check if there's a specific appointment to show
            final prefs = await SharedPreferences.getInstance();
            final appointmentId = prefs.getString('show_appointment_id');
            if (appointmentId != null) {
              // Clear the saved ID
              await prefs.remove('show_appointment_id');
              // Navigate to appointment detail (implement this based on your app structure)
              print('Should navigate to appointment: $appointmentId');
            }
          },
          child: const Text('Check for Saved Appointment'),
        ),
      ),
    );
  }
}
