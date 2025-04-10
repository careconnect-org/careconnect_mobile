import 'package:careconnect/home_screen.dart';
import 'package:flutter/material.dart';
import 'createaccount_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulate login process
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _isLoading = false;
        });

        // TODO: Implement actual authentication logic
        _showLoginResult();
      });
    }
  }

  void _showLoginResult() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Login Result'),
        content: const Text('Login Successfull implemented.'),
        actions: [
          TextButton(
            onPressed: () => 
            Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) =>  HomeScreen()),
      ),
            child: const Text('Okay'),
          ),
        ],
      ),
    );
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
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 70),

                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Email Input
                      _buildEmailInput(),

                      const SizedBox(height: 20),

                      // Password Input
                      _buildPasswordInput(),

                      // Forgot Password
                      _buildForgotPassword(),

                      const SizedBox(height: 20),

                      // Login Button
                      _buildLoginButton(),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Social Login Options
                const Center(child: Text('Or login with')),
                const SizedBox(height: 10),
                _buildSocialLoginOptions(),

                const SizedBox(height: 20),

                // Create Account Option
                _buildCreateAccountOption(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Email Input
  Widget _buildEmailInput() {
    return TextFormField(
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
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }

  // Password Input
  Widget _buildPasswordInput() {
    return TextFormField(
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
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
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
          return 'Please enter your password';
        }
        return null;
      },
    );
  }

  // Forgot Password Text
  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          _showErrorDialog('Forgot Password not implemented');
        },
        child: const Text(
          'Forgot Password?',
          style: TextStyle(color: Colors.blue),
        ),
      ),
    );
  }

  // Login Button
  Widget _buildLoginButton() {
    return _isLoading
        ? const CircularProgressIndicator()
        : ElevatedButton(
            onPressed: _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              minimumSize: const Size(250, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text(
              'Login',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          );
  }

  // Social Login Options
  Widget _buildSocialLoginOptions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: _socialLoginButton(
            icon: Icons.facebook,
            iconColor: Colors.blue,
            text: '',
            onPressed: () {
              // Implement Facebook login
            },
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: _socialLoginButton(
            icon: Icons.g_mobiledata,
            iconColor: Colors.blue,
            text: '',
            onPressed: () {
              // Implement Google login
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _socialLoginButton(
            icon: Icons.apple,
            iconColor: Colors.blue,
            text: '',
            onPressed: () {
              // Implement Apple login
            },
          ),
        ),
      ],
    );
  }

  // Create Account Option
  Widget _buildCreateAccountOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Don\'t have an account?'),
        TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const CreateNewAccountScreen(),
              ),
            );
          },
          child: const Text(
            'Create Account',
            style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // Reused social login button method
  Widget _socialLoginButton({
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
