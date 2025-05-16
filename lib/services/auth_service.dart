import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();
  static const String _tokenKey = 'auth_token';
  static const String _userTypeKey = 'user_type';

  // Store auth token
  Future<void> storeToken(String token, {String? userType}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      if (userType != null) {
        await prefs.setString(_userTypeKey, userType);
      }
    } catch (e) {
      print('Error storing token: $e');
    }
  }

  // Get stored token
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  // Get user type
  Future<String?> getUserType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userTypeKey);
    } catch (e) {
      print('Error getting user type: $e');
      return null;
    }
  }

  // Clear stored token
  Future<void> clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userTypeKey);
      await _notificationService.removeToken();
    } catch (e) {
      print('Error clearing token: $e');
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final token = await getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  // Handle login
  Future<bool> login(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Get the ID token
        final token = await userCredential.user!.getIdToken();
        if (token == null) return false;
        
        // Store the token
        await storeToken(token);
        
        // Initialize notifications
        await _notificationService.initialize();
        
        return true;
      }
      return false;
    } catch (e) {
      print('Error during login: $e');
      return false;
    }
  }

  // Handle logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
      await clearToken();
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Check if token is expired
  Future<bool> isTokenExpired() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return true;

      // Force token refresh
      await user.getIdToken(true);
      return false;
    } catch (e) {
      print('Error checking token expiration: $e');
      return true;
    }
  }

  // Refresh token
  Future<String?> refreshToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final token = await user.getIdToken(true);
      if (token == null) return null;
      
      await storeToken(token);
      return token;
    } catch (e) {
      print('Error refreshing token: $e');
      return null;
    }
  }

  // Store existing token
  Future<void> storeExistingToken() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final token = await user.getIdToken();
        if (token != null) {
          await storeToken(token);
          await _notificationService.initialize();
        }
      }
    } catch (e) {
      print('Error storing existing token: $e');
    }
  }
} 