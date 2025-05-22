import 'package:flutter/material.dart';
import 'welcome_screen.dart';

class CareConnectSplashScreen extends StatefulWidget {
  const CareConnectSplashScreen({Key? key}) : super(key: key);

  @override
  _CareConnectSplashScreenState createState() => _CareConnectSplashScreenState();
}

class _CareConnectSplashScreenState extends State<CareConnectSplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Image.asset(
              'assets/images/icon.png',  
              width: 50, 
              height: 50, 
            ),
            SizedBox(width: 10),  
            Text(
              'CareConnect',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}