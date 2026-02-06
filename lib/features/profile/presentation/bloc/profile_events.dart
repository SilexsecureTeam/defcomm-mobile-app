// profile_event.dart
import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object> get props => [];
}

class MonitorInternetConnection extends ProfileEvent {}

class ConnectionChanged extends ProfileEvent {
  final bool isOnline;
  const ConnectionChanged(this.isOnline);
  @override
  List<Object> get props => [isOnline];
}