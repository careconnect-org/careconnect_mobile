import 'chatdetailscreen.dart';
import 'package:flutter/material.dart';

class MessageHistoryScreen extends StatefulWidget {
  const MessageHistoryScreen({Key? key}) : super(key: key);

  @override
  State<MessageHistoryScreen> createState() => _MessageHistoryScreenState();
}

class _MessageHistoryScreenState extends State<MessageHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
 final List<Map<String, dynamic>> doctors = [
  {
    'name': "Dr. Drake Boeson",
    'image': "assets/images/doctor1.jpg",
    'lastMessage': "My pleasure. All the best for ...",
    'date': "Today",
    'time': "10:00 AM",
  },
  {
    'name': "Dr. Aidan Allende",
    'image': "assets/images/doctor2.jpg",
    'lastMessage': "Your solution is great! 🔥🔥",
    'date': "Yesterday",
    'time': "18:00 PM",
  },
  {
    'name': "Dr. Salvatore Heredia",
    'image': "assets/images/doctor3.jpg",
    'lastMessage': "Thanks for the help doctor 🙏",
    'date': "20/12/2022",
    'time': "10:30 AM",
  },
  {
    'name': "Dr. Delaney Mangino",
    'image': "assets/images/doctor4.jpg",
    'lastMessage': "I have recovered, thank you v...",
    'date': "14/12/2022",
    'time': "17:00 PM",
  },
  {
    'name': "Dr. Beckett Calger",
    'image': "assets/images/doctor5.jpg",
    'lastMessage': "I went there yesterday 😊",
    'date': "26/11/2022",
    'time': "09:30 AM",
  },
  {
    'name': "Dr. Bernard Bliss",
    'image': "assets/images/doctor6.jpg",
    'lastMessage': "IDK what else is there to do ...",
    'date': "09/11/2022",
    'time': "10:00 AM",
  },
  {
    'name': "Dr. Jada Srnsky",
    'image': "assets/images/doctor7.jpg",
    'lastMessage': "I advise you to take a break 🏖️",
    'date': "18/10/2022",
    'time': "15:30 PM",
  },
  {
    'name': "Dr. Randy Wigham",
    'image': "assets/images/doctor8.jpg",
    'lastMessage': "Yeah! You're right. 🔥🔥",
    'date': "07/10/2022",
    'time': "16:00 PM",
  },
];


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(Icons.medical_services, color: Colors.blue),
            const SizedBox(width: 8),
            const Text(
              "History",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "Message"),
            Tab(text: "Voice Call"),
            Tab(text: "Video Call"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMessageList(),
          _buildCallList(isVideo: false),
          _buildCallList(isVideo: true),
        ],
      
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      itemCount: doctors.length,
      itemBuilder: (context, index) {
        final doctor = doctors[index];
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatDetailScreen(doctor: doctor),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundImage: AssetImage(doctor['image']),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        doctor['lastMessage'],
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      doctor['date'],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor['time'],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCallList({required bool isVideo}) {
    return Center(
      child: Text(
        isVideo ? "Video Call History" : "Voice Call History",
        style: const TextStyle(fontSize: 18),
      ),
    );
  }
}

