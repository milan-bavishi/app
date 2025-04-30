import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:examapp/screens/authenticate/authenticate.dart';
import 'package:examapp/screens/home/home.dart';

class Wrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);

    // Return either Home or Authenticate widget based on authentication state
    if (user == null) {
      return Authenticate();
    } else {
      return HomeScreen();
    }
  }
}
