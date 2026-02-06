import 'package:equatable/equatable.dart';
import '../../domain/entities/linked_device.dart';

abstract class LinkedDevicesState extends Equatable {
  const LinkedDevicesState();
  @override
  List<Object?> get props => [];
}

class LinkedDevicesLoading extends LinkedDevicesState {}

class LinkedDevicesLoaded extends LinkedDevicesState {
  final List<LinkedDevice> devices;
  const LinkedDevicesLoaded(this.devices);

  @override
  List<Object?> get props => [devices];
}

class LinkedDevicesEmpty extends LinkedDevicesState {}

class LinkedDevicesError extends LinkedDevicesState {
  final String message;
  const LinkedDevicesError(this.message);

  @override
  List<Object?> get props => [message];
}
