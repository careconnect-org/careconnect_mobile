import 'package:careconnect/login-screen.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'createaccount_screen.dart';

class LetsYouInScreen extends StatefulWidget {
  const LetsYouInScreen({Key? key}) : super(key: key);

  @override
  _LetsYouInScreenState createState() => _LetsYouInScreenState();
}

class _LetsYouInScreenState extends State<LetsYouInScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _handleFacebookSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;
        final userData = await FacebookAuth.instance.getUserData();

        // Send data to your backend
        final response = await http.post(
          Uri.parse(
              'https://careconnect-api-v2kw.onrender.com/api/user/social-login'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'provider': 'facebook',
            'accessToken': accessToken.token,
            'email': userData['email'],
            'name': userData['name'],
          }),
        );

        if (response.statusCode == 200) {
          _handleSuccessfulLogin(response.body);
        } else {
          throw Exception('Failed to login with Facebook');
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to sign in with Facebook';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Send data to your backend
      final response = await http.post(
        Uri.parse(
            'https://careconnect-api-v2kw.onrender.com/api/user/social-login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'provider': 'google',
          'accessToken': googleAuth.accessToken,
          'email': googleUser.email,
          'name': googleUser.displayName,
        }),
      );

      if (response.statusCode == 200) {
        _handleSuccessfulLogin(response.body);
      } else {
        throw Exception('Failed to login with Google');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to sign in with Google';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Send data to your backend
      final response = await http.post(
        Uri.parse(
            'https://careconnect-api-v2kw.onrender.com/api/user/social-login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'provider': 'apple',
          'identityToken': credential.identityToken,
          'email': credential.email,
          'name': '${credential.givenName} ${credential.familyName}',
        }),
      );

      if (response.statusCode == 200) {
        _handleSuccessfulLogin(response.body);
      } else {
        throw Exception('Failed to login with Apple');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to sign in with Apple';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleSuccessfulLogin(String responseBody) {
    final responseData = jsonDecode(responseBody);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Widget _buildSocialLoginButton({
    required IconData icon,
    required String text,
    required Color iconColor,
    required Future<void> Function() onPressed,
  }) {
    return _socialLoginButton(
      icon: icon,
      iconColor: iconColor,
      text: text,
      onPressed: _isLoading ? () {} : () => onPressed(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Image.asset(
                    'assets/images/letmein.png',
                    height: 150,
                    width: 250,
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Let\'s Get Started!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildSocialLoginButton(
                    icon: Icons.facebook,
                    iconColor: Colors.blue,
                    text: 'Continue with Facebook',
                    onPressed: _handleFacebookSignIn,
                  ),
                  const SizedBox(height: 15),
                  _buildSocialLoginButton(
                    icon: Icons.g_mobiledata,
                    iconColor: Colors.red,
                    text: 'Continue with Google',
                    onPressed: _handleGoogleSignIn,
                  ),
                  const SizedBox(height: 15),
                  _buildSocialLoginButton(
                    icon: Icons.apple,
                    iconColor: Colors.black,
                    text: 'Continue with Apple',
                    onPressed: _handleAppleSignIn,
                  ),
                  const SizedBox(height: 30),
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
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size(250, 50),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Don\'t have an account?'),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const CreateNewAccountScreen(),
                                  ),
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
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            if (_errorMessage != null)
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
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
