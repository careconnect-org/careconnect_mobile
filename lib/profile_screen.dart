import 'dart:convert';
import 'package:careconnect/edit_profile_screen.dart';
import 'package:careconnect/helpcenter.dart';
import 'package:careconnect/login-screen.dart';
import 'package:careconnect/notification_screen.dart';
import 'package:careconnect/security_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:careconnect/services/local_storage_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  String? profileImageUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    displayUserProfile();
  }

  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final localUserData = await LocalStorageService.getUserData();
      final authToken = await LocalStorageService.getAuthToken();

      if (localUserData == null || authToken == null) {
        return null;
      }

      try {
        final response = await http.get(
          Uri.parse(
              'https://careconnect-api-v2kw.onrender.com/api/user/profile/${localUserData['_id']}'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        );

        print('Profile API Response Status: ${response.statusCode}');
        print('Profile API Response Body: ${response.body}');

        if (response.statusCode == 200) {
          final profileData = jsonDecode(response.body);
          print('Profile Data: $profileData');

          await LocalStorageService.saveAuthData(
            token: authToken,
            userData: profileData,
          );

          return profileData;
        } else {
          return localUserData;
        }
      } catch (e) {
        print('Error fetching profile: $e');
        return localUserData;
      }
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  void displayUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    final fetchedUserData = await getUserData();

    if (fetchedUserData != null) {
      setState(() {
        userData = fetchedUserData;
        profileImageUrl = fetchedUserData['image'] as String?;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void showLogoutConfirmation() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Are you sure you want to log out?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.blue.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              await _logout();
                            } catch (e) {
                              print('Logout error: $e');
                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Error during logout: ${e.toString()}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: const Text(
                            'Yes, Logout',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _logout() async {
    try {
      final authToken = await LocalStorageService.getAuthToken();
      final userData = await LocalStorageService.getUserData();

      if (authToken == null || userData == null) {
        throw Exception('No authentication data found');
      }

      final userId = userData['_id'];

      if (userId == null) {
        throw Exception('User ID not found');
      }

      final response = await http.post(
        Uri.parse('https://careconnect-api-v2kw.onrender.com/api/user/logout'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'userId': userId}),
      );

      if (response.statusCode == 200 || response.statusCode == 401) {
        await LocalStorageService.clearAllData();
        if (mounted) {
          Navigator.pop(context);
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } else {
        throw Exception(
            'Failed to logout: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      await LocalStorageService.clearAllData();
      if (mounted) {
        Navigator.pop(context);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        automaticallyImplyLeading: false,
        title: const Text(
          "Profile",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: displayUserProfile,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : userData != null
                ? SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: profileImageUrl != null &&
                                      profileImageUrl!.isNotEmpty
                                  ? NetworkImage(profileImageUrl!)
                                  : null,
                              child: profileImageUrl == null ||
                                      profileImageUrl!.isEmpty
                                  ? const Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Colors.grey,
                                    )
                                  : null,
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const EditProfilePage(),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${userData!['firstName']} ${userData!['lastName']}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          userData!['phoneNumber'] ?? '+1 111 467 378 399',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 32),
                        buildMenuItem(
                          icon: Icons.person_outline,
                          title: 'Edit Profile',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EditProfilePage(),
                              ),
                            );
                          },
                        ),
                        buildMenuItem(
                          icon: Icons.notifications_none,
                          title: 'Notification',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NotificationScreen(),
                              ),
                            );
                          },
                        ),
                        buildMenuItem(
                          icon: Icons.security,
                          title: 'Security',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SecurityScreen(),
                              ),
                            );
                          },
                        ),
                        buildMenuItem(
                          icon: Icons.help_outline,
                          title: 'Help Center',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HelpCenterScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 100),
                        buildMenuItem(
                          icon: Icons.logout,
                          title: 'Logout',
                          color: Colors.red,
                          onTap: () {
                            showLogoutConfirmation();
                          },
                        ),
                      ],
                    ),
                  )
                : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Color color = Colors.black,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (subtitle != null)
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[600]),
            ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: Colors.grey[400]),
        ],
      ),
      onTap: onTap,
    );
  }
}
