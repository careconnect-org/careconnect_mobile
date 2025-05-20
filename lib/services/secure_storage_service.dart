import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;

  SecureStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Keys for secure storage
  static const String _authTokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';
  static const String _userRoleKey = 'user_role';
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';
  static const String _firstNameKey = 'first_name';
  static const String _lastNameKey = 'last_name';
  static const String _userImageKey = 'user_image';
  static const String _emailVerifiedKey = 'email_verified';
  static const String _userEmailKey = 'user_email';
  static const String _userPasswordKey = 'user_password';

  // Save authentication data
  Future<void> saveAuthData({
    required String token,
    required Map<String, dynamic> userData,
  }) async {
    try {
      // Save token
      await _storage.write(key: _authTokenKey, value: token);
      
      // Save user data
      await _storage.write(key: _userDataKey, value: jsonEncode(userData));
      
      // Save individual user fields for quick access
      if (userData['_id'] != null) {
        await _storage.write(key: _userIdKey, value: userData['_id']);
      }
      if (userData['username'] != null) {
        await _storage.write(key: _usernameKey, value: userData['username']);
      }
      if (userData['firstName'] != null) {
        await _storage.write(key: _firstNameKey, value: userData['firstName']);
      }
      if (userData['lastName'] != null) {
        await _storage.write(key: _lastNameKey, value: userData['lastName']);
      }
      if (userData['image'] != null) {
        await _storage.write(key: _userImageKey, value: userData['image']);
      }
      if (userData['role'] != null) {
        await _storage.write(key: _userRoleKey, value: userData['role']);
      }
    } catch (e) {
      print('Error saving auth data: $e');
      rethrow;
    }
  }

  // Get authentication token
  Future<String?> getAuthToken() async {
    try {
      return await _storage.read(key: _authTokenKey);
    } catch (e) {
      print('Error getting auth token: $e');
      return null;
    }
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final userDataString = await _storage.read(key: _userDataKey);
      if (userDataString != null) {
        return jsonDecode(userDataString) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Get user role
  Future<String?> getUserRole() async {
    try {
      return await _storage.read(key: _userRoleKey);
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  // Get user ID
  Future<String?> getUserId() async {
    try {
      return await _storage.read(key: _userIdKey);
    } catch (e) {
      print('Error getting user ID: $e');
      return null;
    }
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    try {
      final token = await getAuthToken();
      return token != null;
    } catch (e) {
      print('Error checking authentication: $e');
      return false;
    }
  }

  // Clear all stored data (logout)
  Future<void> clearAllData() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      print('Error clearing data: $e');
      rethrow;
    }
  }

  // Save email verification status
  Future<void> setEmailVerified(bool verified) async {
    try {
      await _storage.write(key: _emailVerifiedKey, value: verified.toString());
    } catch (e) {
      print('Error setting email verification status: $e');
      rethrow;
    }
  }

  // Check if email is verified
  Future<bool> isEmailVerified() async {
    try {
      final verified = await _storage.read(key: _emailVerifiedKey);
      return verified == 'true';
    } catch (e) {
      print('Error checking email verification: $e');
      return false;
    }
  }

  // Save user email and password (for OTP verification)
  Future<void> saveUserCredentials(String email, String password) async {
    try {
      await _storage.write(key: _userEmailKey, value: email);
      await _storage.write(key: _userPasswordKey, value: password);
    } catch (e) {
      print('Error saving user credentials: $e');
      rethrow;
    }
  }

  // Get user email
  Future<String?> getUserEmail() async {
    try {
      return await _storage.read(key: _userEmailKey);
    } catch (e) {
      print('Error getting user email: $e');
      return null;
    }
  }

  // Get user password
  Future<String?> getUserPassword() async {
    try {
      return await _storage.read(key: _userPasswordKey);
    } catch (e) {
      print('Error getting user password: $e');
      return null;
    }
  }
} 