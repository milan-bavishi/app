import 'dart:async';
import 'package:flutter/material.dart';
import 'package:examapp/services/auth_service.dart';
import 'package:examapp/shared/constants.dart';
import 'package:examapp/services/connectivity_service.dart';

class RegisterScreen extends StatefulWidget {
  final Function toggleView;

  RegisterScreen({required this.toggleView});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  int _retryCount = 0;
  final int _maxRetries = 2;

  // text field state
  String email = '';
  String password = '';
  String confirmPassword = '';
  String error = '';

  // Check connectivity before attempting registration
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

  Future<void> _attemptRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Check connectivity first
      if (!await _checkConnectivity()) {
        return;
      }

      try {
        // Log registration attempt
        print('Starting sign up process... (Attempt ${_retryCount + 1})');
        print('Email: $email');
        print('Creating user in Firebase Auth...');

        await _auth.registerWithEmailAndPassword(email, password);
        if (mounted) {
          showSuccessSnackBar(context, 'Registration successful');
          // Navigate to login screen on success
          widget.toggleView();
        }
      } on TimeoutException catch (e) {
        print('Timeout during sign up: $e');

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
              _attemptRegister(); // Retry registration
            }
          } else {
            if (mounted) {
              showErrorSnackBar(
                context,
                'Registration failed after multiple attempts. Please try again later.',
              );
            }
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            if (e.toString().contains('email-already-in-use')) {
              error = 'Email already in use';
            } else if (e.toString().contains('network-request-failed')) {
              error = 'Network error: Please check your internet connection';
            } else if (e.toString().contains('firebase-unreachable')) {
              error =
                  'Unable to reach Firebase servers. Please try again later.';
            } else if (e.toString().contains('invalid-email')) {
              error = 'Invalid email format';
            } else if (e.toString().contains('weak-password')) {
              error = 'Password is too weak. Please use a stronger password.';
            } else {
              error = 'Failed to register: ${e.toString()}';
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
            title: Text('Register for ExamApp'),
            actions: <Widget>[
              TextButton.icon(
                icon: Icon(Icons.person, color: Colors.white),
                label: Text('Sign In', style: TextStyle(color: Colors.white)),
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
                      Icon(
                        Icons.app_registration,
                        size: 80,
                        color: Colors.blue[700],
                      ),
                      SizedBox(height: 20.0),
                      Text(
                        'Create New Account',
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
                      TextFormField(
                        decoration: textInputDecoration.copyWith(
                          labelText: 'Confirm Password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator:
                            (val) =>
                                val != password
                                    ? 'Passwords do not match'
                                    : null,
                        obscureText: true,
                        onChanged: (val) {
                          setState(() => confirmPassword = val);
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
                          'Register',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          setState(() {
                            _retryCount = 0; // Reset retry count on new attempt
                            error = ''; // Clear previous errors
                          });
                          _attemptRegister();
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
