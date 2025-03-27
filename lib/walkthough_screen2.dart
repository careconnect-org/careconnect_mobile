import 'package:flutter/material.dart';

class WalkthroughScreen2 extends StatelessWidget {
  const WalkthroughScreen2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Background with blue circles
            Positioned(
              top: 50,
              left: 0,
              right: 0,
              child: _buildBackgroundCircles(),
            ),
            
            // Main content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Doctor Image
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/doctor.png',
                        width: 200,
                        height: 300,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Main Text
                  const Text(
                    'Thousands of doctors & experts to help your health!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Progress Indicator
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Next Button
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to next screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'Next',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Custom method to create decorative blue circles
  Widget _buildBackgroundCircles() {
    return Stack(
      children: [
        Positioned(
          top: 0,
          right: 100,
          child: _buildCircle(50, Colors.blue.withOpacity(0.2)),
        ),
        Positioned(
          top: 30,
          left: 100,
          child: _buildCircle(30, Colors.blue.withOpacity(0.1)),
        ),
        Positioned(
          top: 60,
          right: 50,
          child: _buildCircle(20, Colors.blue.withOpacity(0.1)),
        ),
      ],
    );
  }

  // Helper method to create individual circles
  Widget _buildCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}