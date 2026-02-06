import 'package:defcomm/core/utils/call_manager.dart';
import 'package:defcomm/init_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:videosdk/videosdk.dart';

import '../../domain/usecases/start_call.dart';
import 'call_event.dart';
import 'call_state.dart';

// class CallBloc extends Bloc<CallEvent, CallState> {
//   final StartCall startCall;

//   Room? _room;

//   bool _hasEstablished = false;

//   CallBloc({required this.startCall}) : super(const CallInitial()) {
//     on<StartCallRequested>(_onStartCallRequested);
//     on<CallEnded>(_onCallEnded);
//      on<RemoteParticipantJoined>(_onRemoteParticipantJoined);
//   }

//   Future<void> _onStartCallRequested(
//     StartCallRequested event,
//     Emitter<CallState> emit,
//   ) async {
//     emit(const CallConnecting());
//     try {
//       final room = await startCall(
//         StartCallParams(
//           meetingId: event.meetingId,
//           displayName: event.displayName,
//           micEnabled: event.micEnabled,
//           camEnabled: event.camEnabled,
//         ),
//       );

//       _room = room;
//       _hasEstablished = false;

//       // when someone else joins, mark call as "connected"
//       room.on(Events.participantJoined, (Participant participant) {
//         if (!_hasEstablished) {
//           _hasEstablished = true;
//           add(const RemoteParticipantJoined());
//         }
//       });

//       // You can attach listeners here (room.on("participant-joined", ...)) if needed

//       // optional: listen to room left / participant left if you like
//       // room.on(Events.roomLeft, (_) { add(const CallEnded()); });

//       // NOTE: we DO NOT emit CallConnected here anymore
//       // emit(CallConnecting()) will remain until RemoteParticipantJoined fires
//     } catch (e) {
//       emit(CallError(e.toString()));
//     }
//   }

//     void _onRemoteParticipantJoined(
//     RemoteParticipantJoined event,
//     Emitter<CallState> emit,
//   ) {
//     final room = _room;
//     if (room != null) {
//       emit(CallConnected(room));
//     }
//   }

//   Future<void> _onCallEnded(
//     CallEnded event,
//     Emitter<CallState> emit,
//   ) async {
//     try {
//       await _room?.leave();
//       _room = null;
//     } catch (_) {}
//      _room = null;
//     _hasEstablished = false;
//     emit(const CallInitial());
//   }
// }

class CallBloc extends Bloc<CallEvent, CallState> {
  final StartCall startCall;

  Room? _room;

  CallBloc({required this.startCall}) : super(const CallInitial()) {
    on<StartCallRequested>(_onStartCallRequested);
    on<CallEnded>(_onCallEnded);
    // 🚫 REMOVE RemoteParticipantJoined & _hasEstablished for now
  }

  Future<void> _onStartCallRequested(
    StartCallRequested event,
    Emitter<CallState> emit,
  ) async {
    emit(const CallConnecting());
    try {
      final room = await startCall(
        StartCallParams(
          meetingId: event.meetingId,
          displayName: event.displayName,
          micEnabled: event.micEnabled,
          camEnabled: event.camEnabled,
        ),
      );

      _room = room;

      // ✅ IMPORTANT: emit CallConnected immediately after joining
      emit(CallConnected(room));

      // (Optional) if you want later:
      // room.on(Events.participantJoined, (Participant p) { ... });
    } catch (e) {
      emit(CallError(e.toString()));
    }
  }

  Future<void> _onCallEnded(
    CallEnded event,
    Emitter<CallState> emit,
  ) async {
    try {
      await _room?.leave();
    } catch (_) {}
    _room = null;
    emit(const CallInitial());

    try {
    serviceLocator<CallManager>().endCall();
  } catch (e) {
    debugPrint('Error releasing global call lock in CallBloc: $e');
  }
  }
}

