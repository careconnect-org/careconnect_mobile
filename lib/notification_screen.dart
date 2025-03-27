import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Notification'),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        children: [
          _buildNotificationItem(
            icon: Icons.cancel,
            iconColor: Colors.red,
            title: 'Appointment Cancelled!',
            subtitle: 'You have successfully cancelled your appointment with Dr. Alan Watson on December 24, 2024, 10:00 am. 80% of the funds will be refunded to your account.',
            time: 'Today | 15:36 PM',
          ),
          _buildNotificationItem(
            icon: Icons.calendar_today,
            iconColor: Colors.blue,
            title: 'Schedule Changed',
            subtitle: 'You have successfully changed schedule to appointment with Dr. Alan Watson on December 29, 2024, 10:00 pm. Don\'t forget to activate your reminder.',
            time: 'Yesterday | 05:23 AM',
          ),
          _buildNotificationItem(
            icon: Icons.check_circle,
            iconColor: Colors.green,
            title: 'Appointment Success!',
            subtitle: 'You have successfully booked an appointment with Dr. Alan Watson on December 24, 2024, 10:00 am. Don\'t forget to activate your reminder.',
            time: 'Dec 22, 2022 | 18:51 PM',
          ),
          _buildNotificationItem(
            icon: Icons.medical_services,
            iconColor: Colors.blue,
            title: 'New Services Available!',
            subtitle: 'You can now make multiple doctor appointments at once. You can also contact your appointment.',
            time: '18 Dec 2022 | 10:52 AM',
          ),
          _buildNotificationItem(
            icon: Icons.credit_card,
            iconColor: Colors.purple,
            title: 'Credit Card Connected!',
            subtitle: 'Your credit card has been successfully linked with Medica. Enjoy our service.',
            time: '15 Dec 2022 | 18:58 PM',
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 4),
          Text(
            time,
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}