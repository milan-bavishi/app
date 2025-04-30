import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:examapp/services/connectivity_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Auth change user stream
  Stream<User?> get user {
    return _auth.authStateChanges();
  }

  // Sign in with email & password
  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      // Check internet connectivity first
      bool hasConnection = await ConnectivityService.hasInternetConnection();
      if (!hasConnection) {
        throw Exception('network-request-failed');
      }

      // Check Firebase reachability
      bool canReachFirebase = await ConnectivityService.isFirebaseReachable();
      if (!canReachFirebase) {
        throw Exception('firebase-unreachable');
      }

      // Set a timeout for the sign-in operation
      final result = await _auth
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              throw TimeoutException('Sign in request timed out');
            },
          );
      return result;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      rethrow;
    } on TimeoutException catch (e) {
      print('Timeout during sign in: $e');
      throw TimeoutException(
        'Network error: Unable to connect to authentication servers. Please check your internet connection and try again.',
      );
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    }
  }

  // Register with email & password
  Future<UserCredential?> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      // Check internet connectivity first
      bool hasConnection = await ConnectivityService.hasInternetConnection();
      if (!hasConnection) {
        throw Exception('network-request-failed');
      }

      // Check Firebase reachability
      bool canReachFirebase = await ConnectivityService.isFirebaseReachable();
      if (!canReachFirebase) {
        throw Exception('firebase-unreachable');
      }

      print('Creating user in Firebase Auth...');
      // Set a timeout for the registration operation
      final result = await _auth
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              throw TimeoutException('Sign up request timed out');
            },
          );
      return result;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      rethrow;
    } on TimeoutException catch (e) {
      print('Timeout during sign up: $e');
      throw TimeoutException(
        'Network error: Unable to connect to authentication servers. Please check your internet connection and try again.',
      );
    } catch (e) {
      print('Error registering: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }
}
