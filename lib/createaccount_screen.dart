import 'fill_profile_screen.dart';
import 'package:flutter/material.dart';
import 'login-screen.dart';

class CreateNewAccountScreen extends StatefulWidget {
  const CreateNewAccountScreen({Key? key}) : super(key: key);

  @override
  _CreateNewAccountScreenState createState() => _CreateNewAccountScreenState();
}

class _CreateNewAccountScreenState extends State<CreateNewAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _signUp() {
    if (_formKey.currentState!.validate()) {
      // Check if passwords match
      if (_passwordController.text != _confirmPasswordController.text) {
        _showErrorDialog('Passwords do not match');
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // Simulate account creation process
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _isLoading = false;
        });

        // Show success dialog
        _showSuccessDialog();
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Okay'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Account Created'),
        content: const Text('Your account has been created successfully!'),
        actions: [
          TextButton(
            onPressed: () {
              // Navigate to login screen
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const FillProfileScreen()),
              );
            },
            child: const Text('Continue to Fill Profile'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),

                const SizedBox(height: 20),

                // Logo
                Center(
                  child: Image.asset(
                    'assets/images/adaptive-icon.png', 
                    height: 150,
                    width: 250,
                  ),
                ),

                const SizedBox(height: 20),

                // Title
                const Center(
                  child: Text(
                    'Create New Account',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Email Input
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Password Input
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Confirm Password Input
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: !_isConfirmPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: const Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isConfirmPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _isConfirmPasswordVisible =
                                    !_isConfirmPasswordVisible;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 30),

                      // Sign Up Button
                      _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _signUp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Social Sign Up Options
                const Center(child: Text('Or sign up with')),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _socialSignUpButton(
                        icon: Icons.facebook,
                        iconColor: Colors.blue,
                        text: '',
                        onPressed: () {
                          // Implement Facebook sign up
                        },
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: _socialSignUpButton(
                        icon: Icons.g_mobiledata,
                        iconColor: Colors.blue,
                        text: '',
                        onPressed: () {
                          // Implement Google sign up
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _socialSignUpButton(
                        icon: Icons.apple,
                        iconColor: Colors.blue,
                        text: '',
                        onPressed: () {
                          // Implement Apple sign up
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Sign in option
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Sign In',
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
      ),
    );
  }

  // Flexible social sign up button method
  Widget _socialSignUpButton({
    required dynamic icon,
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
          if (icon is IconData)
            Icon(icon, size: 24, color: iconColor ?? Colors.black)
          else if (icon is String)
            Image.asset(icon, height: 24, width: 24),

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
