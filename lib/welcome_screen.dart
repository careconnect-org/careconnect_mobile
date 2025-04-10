import 'package:flutter/material.dart';
import 'walkthough_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WalkthroughScreens()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Circular profile images
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: 300,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Positions based on the screenshot
                  _buildCircularProfile('assets/images/Doctor1.png', 
                    left: null, right: 30, top: 20, size: 70),
                  _buildCircularProfile('assets/images/Doctor2.png', 
                    left: 30, right: null, top: 20, size: 70),
                  _buildCircularProfile('assets/images/Doctor3.png', 
                    left: 80, right: null, top: 80, size: 80),
                  _buildCircularProfile('assets/images/Doctor4.png', 
                    left: null, right: 80, top: 80, size: 80),
                  _buildCircularProfile('assets/images/Doctor5.png', 
                    left: null, right: 150, top: 130, size: 90),
                  _buildCircularProfile('assets/images/Doctor1.png', 
                    left: 150, right: null, top: 130, size: 90),
                  _buildCircularProfile('assets/images/Doctor1.png', 
                    left: null, right: 50, bottom: 50, size: 60),
                  _buildCircularProfile('assets/images/Doctor1.png', 
                    left: 50, right: null, bottom: 50, size: 60),
                  _buildCircularProfile('assets/images/Doctor1.png', 
                    left: null, right: null, bottom: 0, size: 70),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            Text(
              'Welcome to CareConnect! 👋',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'The best online Doctor Appointment & Consultation App of the century for your health and medical needs!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularProfile(String imagePath, {
    double? left, 
    double? right, 
    double? top, 
    double? bottom, 
    required double size
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }
}