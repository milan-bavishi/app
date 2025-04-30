import 'dart:async';
import 'package:flutter/material.dart';
import 'package:examapp/services/auth_service.dart';
import 'package:examapp/shared/constants.dart';
import 'package:examapp/services/connectivity_service.dart';

class LoginScreen extends StatefulWidget {
  final Function toggleView;

  LoginScreen({required this.toggleView});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  int _retryCount = 0;
  final int _maxRetries = 2;

  // text field state
  String email = '';
  String password = '';
  String error = '';

  // Check connectivity before attempting login
  Future<bool> _checkConnectivity() async {
    if (!await ConnectivityService.hasInternetConnection()) {
      setState(() {
        error = 'No internet connection. Please check your network settings.';
        _isLoading = false;
      });
      showErrorSnackBar(context, error);
      return false;
    }
    return true;
  }

  Future<void> _attemptLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Check connectivity first
      if (!await _checkConnectivity()) {
        return;
      }

      try {
        // Log login attempt
        print('Starting sign in process... (Attempt ${_retryCount + 1})');
        print('Email: $email');
        print('Authenticating with Firebase...');

        await _auth.signInWithEmailAndPassword(email, password);
        // No need to navigate - Wrapper will handle this automatically
      } on TimeoutException catch (e) {
        print('Timeout during sign in: $e');

        if (mounted) {
          setState(() {
            error =
                'Network error: Please check your internet connection and try again.';
            _isLoading = false;
          });

          // Retry logic
          if (_retryCount < _maxRetries) {
            setState(() {
              _retryCount++;
            });

            // Show retry message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Connection timed out. Retrying in 2 seconds...'),
                duration: Duration(seconds: 2),
              ),
            );

            // Wait 2 seconds before retry
            await Future.delayed(Duration(seconds: 2));
            if (mounted) {
              _attemptLogin(); // Retry login
            }
          } else {
            if (mounted) {
              showErrorSnackBar(
                context,
                'Login failed after multiple attempts. Please try again later.',
              );
            }
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            if (e.toString().contains('user-not-found') ||
                e.toString().contains('wrong-password')) {
              error = 'Invalid email or password';
            } else if (e.toString().contains('network-request-failed')) {
              error = 'Network error: Please check your internet connection';
            } else if (e.toString().contains('firebase-unreachable')) {
              error =
                  'Unable to reach Firebase servers. Please try again later.';
            } else if (e.toString().contains('invalid-email')) {
              error = 'Invalid email format';
            } else if (e.toString().contains('too-many-requests')) {
              error = 'Too many failed login attempts. Please try again later.';
            } else if (e.toString().contains('user-disabled')) {
              error = 'This account has been disabled. Please contact support.';
            } else {
              error = 'Failed to sign in: ${e.toString()}';
            }
            _isLoading = false;
          });

          showErrorSnackBar(context, error);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Loading()
        : Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            backgroundColor: Colors.blue[700],
            elevation: 0.0,
            title: Text('Login to ExamApp'),
            actions: <Widget>[
              TextButton.icon(
                icon: Icon(Icons.person_add, color: Colors.white),
                label: Text('Register', style: TextStyle(color: Colors.white)),
                onPressed: () => widget.toggleView(),
              ),
            ],
          ),
          body: Container(
            padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 50.0),
            child: Center(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      SizedBox(height: 20.0),
                      Icon(Icons.school, size: 80, color: Colors.blue[700]),
                      SizedBox(height: 20.0),
                      Text(
                        'Welcome Back!',
                        style: TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20.0),
                      TextFormField(
                        decoration: textInputDecoration.copyWith(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                        ),
                        validator:
                            (val) => val!.isEmpty ? 'Enter an email' : null,
                        onChanged: (val) {
                          setState(() => email = val);
                        },
                      ),
                      SizedBox(height: 20.0),
                      TextFormField(
                        decoration: textInputDecoration.copyWith(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock),
                        ),
                        validator:
                            (val) =>
                                val!.length < 6
                                    ? 'Enter a password 6+ chars long'
                                    : null,
                        obscureText: true,
                        onChanged: (val) {
                          setState(() => password = val);
                        },
                      ),
                      SizedBox(height: 20.0),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          padding: EdgeInsets.symmetric(
                            horizontal: 50.0,
                            vertical: 12.0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                        ),
                        child: Text(
                          'Sign In',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          setState(() {
                            _retryCount = 0; // Reset retry count on new attempt
                            error = ''; // Clear previous errors
                          });
                          _attemptLogin();
                        },
                      ),
                      SizedBox(height: 12.0),
                      Text(
                        error,
                        style: TextStyle(color: Colors.red, fontSize: 14.0),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
  }
}
