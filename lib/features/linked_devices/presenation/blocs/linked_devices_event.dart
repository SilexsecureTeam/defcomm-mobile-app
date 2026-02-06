import 'package:equatable/equatable.dart';

abstract class LinkedDevicesEvent extends Equatable {
  const LinkedDevicesEvent();
  @override
  List<Object?> get props => [];
}

class LoadLinkedDevices extends LinkedDevicesEvent {}
