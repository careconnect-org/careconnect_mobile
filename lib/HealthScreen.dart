import 'package:flutter/material.dart';

class HealthScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Health Recommendations',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHealthBanner(context),
              SizedBox(height: 20),
              Text(
                'Daily Health Tips',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              _buildHealthTipsList(context),
              SizedBox(height: 24),
              Text(
                'Recommended Checkups',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              _buildCheckupsList(context),
              SizedBox(height: 24),
              Text(
                'Health Articles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              _buildHealthArticles(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHealthBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Health Score',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '85/100',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Great! Keep up your healthy habits',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Navigate to health assessment
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue[700],
              padding: EdgeInsets.symmetric(vertical: 12),
              minimumSize: Size(double.infinity, 0),
            ),
            child: Text('Take Health Assessment'),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthTipsList(BuildContext context) {
    final tips = [
      {
        'icon': Icons.water_drop,
        'title': 'Stay Hydrated',
        'description': 'Drink at least 8 glasses of water daily',
      },
      {
        'icon': Icons.nightlight,
        'title': 'Sleep Well',
        'description': 'Aim for 7-8 hours of quality sleep',
      },
      {
        'icon': Icons.directions_walk,
        'title': 'Regular Exercise',
        'description': '30 minutes of moderate activity daily',
      },
      {
        'icon': Icons.restaurant,
        'title': 'Balanced Diet',
        'description': 'Include fruits and vegetables in every meal',
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: tips.length,
      itemBuilder: (context, index) {
        final tip = tips[index];
        return Card(
          elevation: 2,
          margin: EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                tip['icon'] as IconData,
                color: Colors.blue[700],
              ),
            ),
            title: Text(
              tip['title'] as String,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(tip['description'] as String),
          ),
        );
      },
    );
  }

  Widget _buildCheckupsList(BuildContext context) {
    final checkups = [
      {
        'name': 'Annual Physical',
        'dueIn': 'Due in 2 months',
        'icon': Icons.medical_services,
      },
      {
        'name': 'Dental Checkup',
        'dueIn': 'Overdue by 1 month',
        'icon': Icons.settings_accessibility,
        'urgent': true,
      },
      {
        'name': 'Eye Examination',
        'dueIn': 'Due in 5 months',
        'icon': Icons.visibility,
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: checkups.length,
      itemBuilder: (context, index) {
        final checkup = checkups[index];
        final bool isUrgent =
            checkup.containsKey('urgent') && checkup['urgent'] == true;

        return Card(
          elevation: 2,
          margin: EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isUrgent ? Colors.red[50] : Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                checkup['icon'] as IconData,
                color: isUrgent ? Colors.red : Colors.blue[700],
              ),
            ),
            title: Text(
              checkup['name'] as String,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              checkup['dueIn'] as String,
              style: TextStyle(
                color: isUrgent ? Colors.red : null,
              ),
            ),
            trailing: ElevatedButton(
              onPressed: () {
                // Navigate to appointment booking
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isUrgent ? Colors.red : Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text('Schedule'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHealthArticles(BuildContext context) {
    final articles = [
      {
        'title': 'The Benefits of Mediterranean Diet',
        'image': 'assets/images/diet.jpg',
        'readTime': '5 min read',
      },
      {
        'title': 'How Stress Affects Your Body',
        'image': 'assets/images/stress.jpg',
        'readTime': '8 min read',
      },
      {
        'title': 'Building a Strong Immune System',
        'image': 'assets/images/immune.jpg',
        'readTime': '6 min read',
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: articles.length,
      itemBuilder: (context, index) {
        final article = articles[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.asset(
                  article['image'] as String,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child:
                          Icon(Icons.image, size: 50, color: Colors.grey[600]),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article['title'] as String,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          article['readTime'] as String,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        // Navigate to article
                      },
                      child: Text('Read Article'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
