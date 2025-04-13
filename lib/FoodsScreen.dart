import 'package:flutter/material.dart';

class FoodsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Foods"),
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
