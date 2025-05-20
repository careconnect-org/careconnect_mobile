import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'secure_storage_service.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;

  LocalStorageService._internal();

  final SecureStorageService _secureStorage = SecureStorageService();

  // Keys for non-sensitive data
  static const String _themeKey = 'theme_mode';
  static const String _languageKey = 'language';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _twoFactorEnabledKey = 'two_factor_enabled';
  static const String _darkModeKey = 'dark_mode';

  // Save authentication data
  static Future<void> saveAuthData({
    required String token,
    required Map<String, dynamic> userData,
  }) async {
    await SecureStorageService().saveAuthData(
      token: token,
      userData: userData,
    );
  }

  // Get authentication token
  static Future<String?> getAuthToken() async {
    return await SecureStorageService().getAuthToken();
  }

  // Get user data
  static Future<Map<String, dynamic>?> getUserData() async {
    return await SecureStorageService().getUserData();
  }

  // Get user role
  static Future<String?> getUserRole() async {
    return await SecureStorageService().getUserRole();
  }

  // Get user ID
  static Future<String?> getUserId() async {
    return await SecureStorageService().getUserId();
  }

  static Future<String?> getUserName() async {
    return await SecureStorageService().getUserName();
  }

  // Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    return await SecureStorageService().isAuthenticated();
  }

  // Clear all stored data (logout)
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await SecureStorageService().clearAllData();
  }

  // Save email verification status
  static Future<void> setEmailVerified(bool verified) async {
    await SecureStorageService().setEmailVerified(verified);
  }

  // Check if email is verified
  static Future<bool> isEmailVerified() async {
    return await SecureStorageService().isEmailVerified();
  }

  // Save user credentials for OTP verification
  static Future<void> saveUserCredentials(String email, String password) async {
    await SecureStorageService().saveUserCredentials(email, password);
  }

  // Get user email
  static Future<String?> getUserEmail() async {
    return await SecureStorageService().getUserEmail();
  }

  // Get user password
  static Future<String?> getUserPassword() async {
    return await SecureStorageService().getUserPassword();
  }

  // Non-sensitive data methods
  Future<void> setThemeMode(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme);
  }

  Future<String?> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey);
  }

  Future<void> setLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language);
  }

  Future<String?> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
  }

  Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }

  Future<bool> getBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  Future<void> setTwoFactorEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_twoFactorEnabledKey, enabled);
  }

  Future<bool> getTwoFactorEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_twoFactorEnabledKey) ?? false;
  }

  Future<void> setDarkMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, enabled);
  }

  Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeKey) ?? false;
  }

  // Save chat room ID for a specific doctor
  static Future<void> saveChatRoomId(String doctorId, String chatRoomId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('chat_room_${doctorId}', chatRoomId);
      print('Chat room ID stored for doctor $doctorId: $chatRoomId');
    } catch (e) {
      print('Error storing chat room ID: $e');
    }
  }

  // Get chat room ID for a specific doctor
  static Future<String?> getChatRoomId(String doctorId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chatRoomId = prefs.getString('chat_room_${doctorId}');
      return chatRoomId;
    } catch (e) {
      print('Error getting chat room ID: $e');
      return null;
    }
  }

  // Finds or creates a consistent chat room ID
  static Future<String> _getOrCreateConsistentChatRoomId(
      String doctorId) async {
    String? chatRoomId = await getChatRoomId(doctorId);
    if (chatRoomId == null) {
      chatRoomId = '${DateTime.now().millisecondsSinceEpoch}-$doctorId';
      await saveChatRoomId(doctorId, chatRoomId);
    }
    return chatRoomId;
  }

  // Gets all messages
  static Future<List<Map<String, dynamic>>> fetchAllMessages(
      String doctorId) async {
    final chatRoomId = await _getOrCreateConsistentChatRoomId(doctorId);
    // Logic to fetch all messages from the chat room
    return [];
  }

  // Gets messages sent by the current user
  static Future<List<Map<String, dynamic>>> fetchSentMessages(
      String doctorId) async {
    final chatRoomId = await _getOrCreateConsistentChatRoomId(doctorId);
    // Logic to fetch sent messages from the chat room
    return [];
  }

  // Gets messages received from others
  static Future<List<Map<String, dynamic>>> fetchReceivedMessages(
      String doctorId) async {
    final chatRoomId = await _getOrCreateConsistentChatRoomId(doctorId);
    // Logic to fetch received messages from the chat room
    return [];
  }

  // Gets the most recent message
  static Future<Map<String, dynamic>?> fetchLatestMessage(
      String doctorId) async {
    final chatRoomId = await _getOrCreateConsistentChatRoomId(doctorId);
    // Logic to fetch the latest message from the chat room
    return null;
  }

  // Refreshes the message stream
  static Future<void> _refreshMessages(String doctorId) async {
    final chatRoomId = await _getOrCreateConsistentChatRoomId(doctorId);
    // Logic to refresh messages in the chat room
  }
}
