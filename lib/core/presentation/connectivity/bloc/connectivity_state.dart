part of 'connectivity_cubit.dart';

abstract class ConnectivityState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ConnectivityInitial extends ConnectivityState {}

class ConnectivityLoading extends ConnectivityState {}

class ConnectivityConnected extends ConnectivityState {
  final ConnectivityResult connectionType;
  
  ConnectivityConnected(this.connectionType);
  
  @override
  List<Object?> get props => [connectionType];
}

class ConnectivityDisconnected extends ConnectivityState {}