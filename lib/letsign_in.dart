import 'package:flutter/material.dart';
import 'createaccount_screen.dart'; 

class LetsYouInScreen extends StatelessWidget {
  const LetsYouInScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              
              // Back Button
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Illustration
              Image.asset(
                'assets/images/letmein.png', // Replace with your illustration
                height: 150,
                width: 250,
              ),
              
              const SizedBox(height: 40),
              
              // Title
              const Text(
                'Let\'s you in',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Social Login Buttons
              _socialLoginButton(
                icon: Icons.facebook,
                iconColor: Colors.blue,
                text: 'Continue with Facebook',
                onPressed: () {
                  // Implement Facebook login
                },
              ),
              
              const SizedBox(height: 15),
              
              _socialLoginButton(
                icon: Icons.g_mobiledata,
                iconColor: Colors.red,
                text: 'Continue with Google',
                onPressed: () {
                  // Implement Google login
                },
              ),
              
              const SizedBox(height: 15),
              
              _socialLoginButton(
                icon: Icons.apple,
                iconColor: Colors.black,
                text: 'Continue with Apple',
                onPressed: () {
                  // Implement Apple login
                },
              ),
              
              const SizedBox(height: 30),
              
              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[300])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'or',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey[300])),
                ],
              ),
              
              const SizedBox(height: 30),
              
              // Sign in with password button
              ElevatedButton(
                onPressed: () {
                  // Navigate to sign in with password screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Sign in with password',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Sign up option
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Don\'t have an account?'),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(
                          builder: (context) => const CreateNewAccountScreen()
                        )
                      );
                    },
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialLoginButton({
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
    Color? iconColor,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.grey[300]!),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon, 
            size: 24, 
            color: iconColor ?? Colors.black,
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}