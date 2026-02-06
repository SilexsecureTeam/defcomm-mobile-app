// profile_bloc.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:defcomm/features/profile/presentation/bloc/profile_events.dart';
import 'package:defcomm/features/profile/presentation/bloc/profile_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  StreamSubscription? _connectivitySubscription;

  ProfileBloc() : super(const ProfileState()) {
    on<MonitorInternetConnection>(_onMonitorInternetConnection);
    on<ConnectionChanged>(_onConnectionChanged);
  }

  Future<void> _onMonitorInternetConnection(
    MonitorInternetConnection event,
    Emitter<ProfileState> emit,
  ) async {
    final List<ConnectivityResult> result = await Connectivity().checkConnectivity();
    final bool isOnline = !result.contains(ConnectivityResult.none);
    
    add(ConnectionChanged(isOnline));

    _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final bool hasNet = !results.contains(ConnectivityResult.none);
      add(ConnectionChanged(hasNet));
    });
  }

  void _onConnectionChanged(
    ConnectionChanged event,
    Emitter<ProfileState> emit,
  ) {
    emit(state.copyWith(isOnline: event.isOnline));
  }
}