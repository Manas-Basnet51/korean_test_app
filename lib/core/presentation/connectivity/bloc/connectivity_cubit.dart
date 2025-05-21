import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:korean_language_app/core/network/network_info.dart';

part 'connectivity_state.dart';

class ConnectivityCubit extends Cubit<ConnectivityState> {
  final NetworkInfo networkInfo;
  StreamSubscription? _connectivitySubscription;
  
  ConnectivityCubit({required this.networkInfo}) : super(ConnectivityInitial()) {
    _initConnectivity();
    _connectivitySubscription = networkInfo.connectivityChanges.listen(_updateConnectionStatus);
  }
  
  Future<void> _initConnectivity() async {
    emit(ConnectivityLoading());
    await checkConnectivity();
  }
  
  Future<void> checkConnectivity() async {
    try {
      final result = await networkInfo.connectivityStatus;
      _updateConnectionStatus(result);
    } catch (_) {
      emit(ConnectivityDisconnected());
    }
  }
  
  void _updateConnectionStatus(ConnectivityResult result) {
    if (result == ConnectivityResult.none) {
      emit(ConnectivityDisconnected());
    } else {
      emit(ConnectivityConnected(result));
    }
  }
  
  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }
}