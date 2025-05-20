import 'package:careconnect/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/notification_service.dart';
import 'dart:convert';
import 'firebase_options.dart';
import 'letsign_in.dart';
import 'package:careconnect/services/local_storage_service.dart';
import 'screens/sports_crud_screen.dart';
import 'screens/food_crud_screen.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'services/auth_service.dart';

// Use the global navigator key from the NotificationService
final GlobalKey<NavigatorState> navigatorKey = NotificationService.navigatorKey;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Store existing token if user is logged in
  await AuthService().storeExistingToken();
  
  // Start the app
  runApp(const MyApp());

  // Perform additional initialization
  _completeInitialization();
}

Future<void> _completeInitialization() async {
  try {
    print('Starting additional initialization...');
    
    // Check if Firebase is initialized
    if (Firebase.apps.isEmpty) {
      print('Firebase not initialized, attempting to initialize...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    // Initialize notification service
    print('Initializing notification service...');
    await NotificationService().initialize();
    print('Notification service initialized');

    // Check user role and subscribe to topics
    print('Checking user role...');
    await _checkUserRoleAndSubscribe();
    print('User role check completed');
  } catch (e) {
    print('Error during additional initialization: $e');
  }
}

Future<void> _checkUserRoleAndSubscribe() async {
  try {
    final userRole = await LocalStorageService.getUserRole();
    if (userRole != null) {
      // Subscribe to role-specific topics
      if (userRole.toLowerCase() == 'admin') {
        await NotificationService().subscribeToAdminNotifications();
      }
      // Subscribe to general appointment notifications for all users
      await NotificationService().initialize(); // This will subscribe to 'appointments' topic
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
            final userData = await LocalStorageService.getUserData();
            final appointmentId = userData?['show_appointment_id'];
            if (appointmentId != null) {
              // Clear the saved ID
              await LocalStorageService.saveAuthData(
                token: await LocalStorageService.getAuthToken() ?? '',
                userData: {...?userData, 'show_appointment_id': null},
              );
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

types.TextMessage messageFromFirestore(Map<String, dynamic> doc) {
  return types.TextMessage(
    id: doc['id'],
    author: types.User(id: doc['authorId']),
    createdAt: doc['createdAt'],
    text: doc['text'],
  );
}

Stream<List<types.TextMessage>> getMessagesStream(String chatRoomId) {
  return FirebaseFirestore.instance
      .collection('chatRooms')
      .doc(chatRoomId)
      .collection('messages')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => messageFromFirestore(doc.data()))
          .toList());
}

Future<void> sendMessage(String chatRoomId, types.PartialText message, String userId) async {
  final docRef = FirebaseFirestore.instance
      .collection('chatRooms')
      .doc(chatRoomId)
      .collection('messages')
      .doc();

  await docRef.set({
    'id': docRef.id,
    'authorId': userId,
    'createdAt': DateTime.now().millisecondsSinceEpoch,
    'text': message.text,
  });
}

class ChatScreen extends StatelessWidget {
  final String chatRoomId;
  final types.User currentUser;

  const ChatScreen({
    Key? key,
    required this.chatRoomId,
    required this.currentUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<types.TextMessage>>(
      stream: getMessagesStream(chatRoomId),
      builder: (context, snapshot) {
        final messages = snapshot.data ?? [];
        return Chat(
          messages: messages,
          onSendPressed: (partial) => sendMessage(chatRoomId, partial, currentUser.id),
          user: currentUser,
        );
      },
    );
  }
}
