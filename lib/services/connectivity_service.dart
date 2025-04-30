import 'dart:io';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();
  static final InternetConnectionChecker _connectionChecker =
      InternetConnectionChecker();

  // Check if the device has internet connectivity
  static Future<bool> hasInternetConnection() async {
    try {
      // First check if we have any connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        print('Network connectivity: No connectivity detected');
        return false;
      }

      // Then verify if we actually have internet
      final hasConnection = await _connectionChecker.hasConnection;
      print(
        'Network connectivity: ${hasConnection ? 'Available' : 'Not available'}',
      );
      return hasConnection;
    } catch (e) {
      print('Network connectivity check error: $e');
      return false;
    }
  }

  // Check if Firebase is reachable
  static Future<bool> isFirebaseReachable() async {
    try {
      // First check general internet connectivity
      if (!await hasInternetConnection()) {
        return false;
      }

      // Try to connect to Firebase API
      final result = await InternetAddress.lookup(
        'firebase.google.com',
      ).timeout(Duration(seconds: 5));

      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('Firebase connectivity: Available');
        return true;
      }
    } on SocketException catch (_) {
      print('Firebase connectivity: Not available (SocketException)');
      return false;
    } on TimeoutException catch (_) {
      print('Firebase connectivity: Not available (TimeoutException)');
      return false;
    } catch (e) {
      print('Firebase connectivity check error: $e');
      return false;
    }

    print('Firebase connectivity: Not available (unknown reason)');
    return false;
  }

  // Listen for connectivity changes
  static Stream<ConnectivityResult> get connectivityStream {
    return _connectivity.onConnectivityChanged;
  }

  // Listen for internet connection changes
  static Stream<InternetConnectionStatus> get internetStatusStream {
    return _connectionChecker.onStatusChange;
  }
}
