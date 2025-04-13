import 'package:flutter/material.dart';

class SportsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sports"),
      ),
      body: Center(
        child: Text(
          'Welcome to the Doctors Page!',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
