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
    final result = await connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  @override
  Future<ConnectivityResult> get connectivityStatus async {
    final result = await connectivity.checkConnectivity();
    return result;
  }

  @override
  Stream<ConnectivityResult> get connectivityChanges => connectivity.onConnectivityChanged;
}