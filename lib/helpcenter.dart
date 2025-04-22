import 'package:flutter/material.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({Key? key}) : super(key: key);

  @override
  _HelpCenterScreenState createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _faqItems = [
    {
      'question': 'What is CareConnect?',
      'answer':
          'CareConnect is a health management app that bridges the gap between patients and healthcare professionals. It allows you to schedule medical appointments, receive feedback from doctors, and chat with healthcare providers. The app offers both light and dark modes for enhanced user experience, ensuring efficient communication and better healthcare management.'
    },
    {
      'question': 'How do I book an appointment?',
      'answer':
          'To book an appointment: 1) Log in to your account 2) Browse available doctors 3) Select your preferred consultation time 4) Confirm your booking. You can view your appointment history and upcoming appointments in your profile.'
    },
    {
      'question': 'How does the doctor feedback system work?',
      'answer':
          'After each consultation, your doctor will provide personalized feedback about your health condition and next steps. This feedback will be available in your profile under the appointment history section. You can review it anytime for reference.'
    },
    {
      'question': 'How do I use the chat feature?',
      'answer':
          'The real-time chat feature allows secure communication with your healthcare providers. You can send messages for follow-up questions and receive advice. Access the chat through your ongoing consultations or doctor\'s profile.'
    },
    {
      'question': 'How do I switch between dark and light mode?',
      'answer':
          'CareConnect supports both dark and light modes. You can change the appearance in Settings. The app automatically detects your system\'s appearance settings, but you can manually toggle between modes to suit your preference.'
    },
    {
      'question': 'Is my data secure?',
      'answer':
          'Yes, CareConnect takes your privacy seriously. All user data is stored securely with encryption. We follow strict privacy guidelines and industry-standard security measures to protect your personal and medical information.'
    },
    {
      'question': 'How do I view my appointment history?',
      'answer':
          'You can view your past appointments and doctor feedback in your profile under the "Appointment History" section. This includes consultation details, doctor\'s notes, and any prescribed follow-up actions.'
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Help Center',
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.black),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: 'FAQ'),
            Tab(text: 'Contact us'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFAQTab(),
          _buildContactTab(),
        ],
      ),
    );
  }

  Widget _buildFAQTab() {
    return Column(
      children: [
        const SizedBox(height: 16),
        const Text(
          'Frequently Asked Questions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: const Icon(Icons.tune, color: Colors.grey),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _faqItems.length,
            itemBuilder: (context, index) {
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: ExpansionTile(
                  title: Text(
                    _faqItems[index]['question']!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(
                        _faqItems[index]['answer']!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContactTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContactOption(
            icon: Icons.email_outlined,
            title: 'Email Support',
            subtitle: 'support@careconnect.com',
            onTap: () {},
          ),
          const SizedBox(height: 16),
          _buildContactOption(
            icon: Icons.phone_outlined,
            title: 'Phone Support',
            subtitle: '+1 234 567 890',
            onTap: () {},
          ),
          const SizedBox(height: 16),
          _buildContactOption(
            icon: Icons.chat_bubble_outline,
            title: 'Live Chat',
            subtitle: 'Available 24/7',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
