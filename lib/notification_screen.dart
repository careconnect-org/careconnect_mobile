import 'package:flutter/material.dart';

// Model class for Notification
class NotificationItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;

  NotificationItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
  });
}

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // Simulate an API call to fetch notifications
  Future<List<NotificationItem>> fetchNotifications() async {
    await Future.delayed(Duration(seconds: 2)); // simulate network delay

    // Return one manual notification for now (mocked)
    return [
      NotificationItem(
        icon: Icons.cancel,
        iconColor: Colors.red,
        title: 'Appointment Cancelled!',
        subtitle:
            'You have successfully cancelled your appointment with Dr. Alan Watson on December 24, 2024, 10:00 am. 80% of the funds will be refunded to your account.',
        time: 'Today | 15:36 PM',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Notifications'),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: FutureBuilder<List<NotificationItem>>(
        future: fetchNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load notifications'),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Text('No notifications yet.'),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final item = notifications[index];
              return _buildNotificationItem(item);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(NotificationItem item) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      leading: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: item.iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(item.icon, color: item.iconColor),
      ),
      title: Text(
        item.title,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 4),
          Text(
            item.subtitle,
            style: TextStyle(color: Colors.grey[700]),
          ),
          SizedBox(height: 4),
          Text(
            item.time,
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
