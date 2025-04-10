import 'package:flutter/material.dart';
import 'letsign_in.dart'; // Make sure to create this file

class WalkthroughScreens extends StatefulWidget {
  const WalkthroughScreens({Key? key}) : super(key: key);

  @override
  _WalkthroughScreensState createState() => _WalkthroughScreensState();
}

class _WalkthroughScreensState extends State<WalkthroughScreens> {
  int _currentPage = 0;

  final List<Map<String, dynamic>> _walkthroughPages = [
    {
      'image': 'assets/images/MariaBackblur.png',
      'title': 'Your health. Our priority. Thousands of doctors ready to help.!',
      'description': 'Get instant access to trusted doctors and personalized health advice — anytime, anywhere.',
    },
    {
      'image': 'assets/images/walk2.png',
      'title': 'Quick and Easy Consultations',
      'description': 'Book appointments and get medical advice with just a few taps.',
    },
    {
      'image': 'assets/images/walk3.png',
      'title': 'Secure and Confidential',
      'description': 'Your health information is always private and protected.',
    },
  ];

  void _nextPage() {
    if (_currentPage < _walkthroughPages.length - 1) {
      setState(() {
        _currentPage++;
      });
    } else {
      // Navigate to the login screen
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => const LetsYouInScreen())
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPageData = _walkthroughPages[_currentPage];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Background with image circle
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/calendarmodal.png'),
                        fit: BoxFit.cover,
                        opacity: 0.5,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Image.asset(
                    currentPageData['image'],
                    width: 200,
                    height: 300,
                    fit: BoxFit.contain,
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Main Text
              Text(
                currentPageData['title'],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 16),

              // Description Text
              Text(
                currentPageData['description'],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),

              const SizedBox(height: 30),

              // Progress Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _walkthroughPages.length,
                  (index) => Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: index <= _currentPage
                          ? Colors.blue
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Next Button
              ElevatedButton(
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  _currentPage < _walkthroughPages.length - 1
                      ? 'Next'
                      : 'Get Started',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}