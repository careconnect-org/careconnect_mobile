import 'package:flutter/material.dart';
import 'package:careconnect/fill_profile_screen.dart';
import 'package:careconnect/updatepassword_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        title: const Text(
          "My Profile",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Avatar
            CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage("assets/images/user_avatar.png"),
            ),

            const SizedBox(height: 12),

            // Name & Email
            const Text(
              "John Doe",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              "john.doe@example.com",
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 24),

            // Info Cards
            _buildInfoCard(Icons.phone, "Phone", "+123 456 7890"),
            _buildInfoCard(Icons.calendar_today, "DOB", "01 Jan 1990"),
            _buildInfoCard(Icons.location_on, "Location", "Kigali, Rwanda"),

            const SizedBox(height: 30),

            // Update Profile Button
            _buildActionButton(
              context,
              icon: Icons.edit,
              label: "Update Profile",
              onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const FillProfileScreen()),
  );
},
            ),

            const SizedBox(height: 12),

            // Change Password Button
            _buildActionButton(
              context,
              icon: Icons.lock_outline,
              label: "Change Password",
              onTap: () {
                 Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UpdatePasswordScreen(),
      ),
    );
              },
            ),

            const SizedBox(height: 12),

            // Logout Button
            _buildActionButton(
              context,
              icon: Icons.logout,
              label: "Logout",
              isLogout: true,
              onTap: () {
                // TODO: Handle logout
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap,
      bool isLogout = false}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: isLogout ? Colors.red[400] : Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white)),
        onPressed: onTap,
      ),
    );
  }
}
