import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SportsScreen extends StatelessWidget {
  const SportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text('Sports Recommendations', 
        style: TextStyle(color: Colors.white
        ),),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSportsBanner(context),
              const SizedBox(height: 20),
              const Text(
                'Recommended Activities',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildSportsGrid(context),
              const SizedBox(height: 24),
              const Text(
                'Weekly Goals',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildWeeklyGoals(context),
              const SizedBox(height: 24),
              const Text(
                'Exercise Tutorials',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildExerciseTutorials(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSportsBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[700]!, Colors.green[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Activity Status',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                    SizedBox(height: 8),
                    Text('75% Complete',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 6),
                    Text('You\'re on track to meet your weekly goal!',
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
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
                child: const Center(
                  child:
                      Icon(Icons.directions_run, color: Colors.white, size: 36),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: 0.75,
            backgroundColor: Colors.white30,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 8,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Navigate to activity tracking
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.green[700],
              padding: const EdgeInsets.symmetric(vertical: 12),
              minimumSize: const Size(double.infinity, 0),
            ),
            child: const Text('Track Today\'s Activity'),
          ),
        ],
      ),
    );
  }

  Widget _buildSportsGrid(BuildContext context) {
    final sports = [
      {'name': 'Walking', 'icon': Icons.directions_walk, 'color': Colors.blue},
      {'name': 'Running', 'icon': Icons.directions_run, 'color': Colors.red},
      {
        'name': 'Cycling',
        'icon': Icons.directions_bike,
        'color': Colors.orange
      },
      {'name': 'Swimming', 'icon': Icons.pool, 'color': Colors.indigo},
      {'name': 'Yoga', 'icon': Icons.self_improvement, 'color': Colors.purple},
      {'name': 'Gym', 'icon': Icons.fitness_center, 'color': Colors.green},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: sports.length,
      itemBuilder: (context, index) {
        final sport = sports[index];
        return InkWell(
          onTap: () {
            // Navigate to sport detail
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: (sport['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (sport['color'] as Color).withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(sport['icon'] as IconData,
                    color: sport['color'] as Color, size: 32),
                const SizedBox(height: 8),
                Text(sport['name'] as String,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeeklyGoals(BuildContext context) {
    final goals = [
      {
        'activity': 'Walking',
        'target': '10,000 steps',
        'current': '7,500 steps',
        'progress': 0.75
      },
      {
        'activity': 'Cardio',
        'target': '150 minutes',
        'current': '90 minutes',
        'progress': 0.6
      },
      {
        'activity': 'Strength Training',
        'target': '3 sessions',
        'current': '2 sessions',
        'progress': 0.67
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: goals.length,
      itemBuilder: (context, index) {
        final goal = goals[index];
        final progress = goal['progress'] as double;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(goal['activity'] as String,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExerciseTutorials(BuildContext context) {
    final tutorials = [
      {
        'title': 'Proper Running Technique',
        'image': 'assets/images/running.jpg',
        'youtubeLink': 'https://www.youtube.com/watch?v=_kGESn8ArrU',
      },
      {
        'title': 'Home Workout Without Equipment',
        'image': 'assets/images/home_workout.jpg',
        'youtubeLink': 'https://www.youtube.com/watch?v=XJj4XjwDo6Y',
      },
      {
        'title': 'Yoga for Flexibility',
        'image': 'assets/images/yoga.jpg',
        'youtubeLink': 'https://www.youtube.com/watch?v=FI51zRzgIe4',
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tutorials.length,
      itemBuilder: (context, index) {
        final tutorial = tutorials[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.only(bottom: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 120,
                height: 100,
                child: Image.asset(
                  tutorial['image'] as String,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child:
                          Icon(Icons.image, size: 40, color: Colors.grey[600]),
                    );
                  },
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tutorial['title'] as String,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      ElevatedButton(
                        onPressed: () async {
                          final url =
                              Uri.parse(tutorial['youtubeLink'] as String);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url,
                                mode: LaunchMode.externalApplication);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Could not open the link.')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                        child: const Text('Watch Tutorial'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
