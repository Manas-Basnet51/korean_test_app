import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<ConnectivityResult> get connectivityChanges;
  Future<ConnectivityResult> get connectivityStatus;
}

class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;

  NetworkInfoImpl({required this.connectivity});

  @override
  Future<bool> get isConnected async {
    try {
      final connectivityResult = await connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }
      
      // Additional check for actual internet connectivity
      try {
        final result = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 5));
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } on SocketException catch (_) {
        return false;
      } on TimeoutException catch (_) {
        return false;
      }
    } catch (e) {
      // If there's any error checking connectivity, assume not connected
      return false;
    }
  }


  @override
  Future<ConnectivityResult> get connectivityStatus async {
    final result = await connectivity.checkConnectivity();
    return result;
  }

  @override
  Stream<ConnectivityResult> get connectivityChanges => connectivity.onConnectivityChanged;
}