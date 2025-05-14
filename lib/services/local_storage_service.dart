import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _authTokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';
  static const String _userRoleKey = 'user_role';
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';
  static const String _firstNameKey = 'first_name';
  static const String _lastNameKey = 'last_name';
  static const String _userImageKey = 'user_image';
  static const String _emailVerifiedKey = 'email_verified';

  // Save authentication data
  static Future<void> saveAuthData({
    required String token,
    required Map<String, dynamic> userData,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save token
    await prefs.setString(_authTokenKey, token);
    
    // Save user data
    await prefs.setString(_userDataKey, jsonEncode(userData));
    
    // Save individual user fields for quick access
    if (userData['_id'] != null) {
      await prefs.setString(_userIdKey, userData['_id']);
    }
    if (userData['username'] != null) {
      await prefs.setString(_usernameKey, userData['username']);
    }
    if (userData['firstName'] != null) {
      await prefs.setString(_firstNameKey, userData['firstName']);
    }
    if (userData['lastName'] != null) {
      await prefs.setString(_lastNameKey, userData['lastName']);
    }
    if (userData['image'] != null) {
      await prefs.setString(_userImageKey, userData['image']);
    }
    if (userData['role'] != null) {
      await prefs.setString(_userRoleKey, userData['role']);
    }
  }

  // Get authentication token
  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_authTokenKey);
  }

  // Get user data
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userDataKey);
    if (userDataString != null) {
      return jsonDecode(userDataString) as Map<String, dynamic>;
    }
    return null;
  }

  // Get user role
  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  // Get user ID
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  // Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    final token = await getAuthToken();
    return token != null;
  }

  // Clear all stored data (logout)
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authTokenKey);
    await prefs.remove(_userDataKey);
    await prefs.remove(_userRoleKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_firstNameKey);
    await prefs.remove(_lastNameKey);
    await prefs.remove(_userImageKey);
    await prefs.remove(_emailVerifiedKey);
  }

  // Save email verification status
  static Future<void> setEmailVerified(bool verified) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_emailVerifiedKey, verified);
  }

  // Check if email is verified
  static Future<bool> isEmailVerified() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_emailVerifiedKey) ?? false;
  }
} 