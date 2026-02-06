import 'package:defcomm/features/linked_devices/domain/entities/linked_device.dart';
import 'package:defcomm/features/linked_devices/domain/usecase/get_linked_devices.dart';
import 'package:defcomm/features/linked_devices/presenation/blocs/linked_devices_event.dart';
import 'package:defcomm/features/linked_devices/presenation/blocs/linked_devices_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LinkedDevicesBloc extends Bloc<LinkedDevicesEvent, LinkedDevicesState> {
  final GetLinkedDevices getLinkedDevices;

  LinkedDevicesBloc(
    this.getLinkedDevices, {
    List<LinkedDevice>? initialDevices,
  }) : super(
          (initialDevices != null && initialDevices.isNotEmpty)
              ? LinkedDevicesLoaded(initialDevices)
              : LinkedDevicesLoading(),
        ) {
    on<LoadLinkedDevices>(_onLoad);
  }

  Future<void> _onLoad(
    LoadLinkedDevices event,
    Emitter<LinkedDevicesState> emit,
  ) async {
 
    if (state is! LinkedDevicesLoaded) {
      emit(LinkedDevicesLoading());
    }

    try {
      final devices = await getLinkedDevices();
      
      if (devices.isEmpty) {
        emit(LinkedDevicesEmpty());
      } else {
        emit(LinkedDevicesLoaded(devices));
      }
    } catch (e) {
      if (state is LinkedDevicesLoaded) {
        debugPrint("Background refresh failed: $e");
      } else {
        emit(const LinkedDevicesError('Failed to load linked devices'));
      }
    }
  }
}
