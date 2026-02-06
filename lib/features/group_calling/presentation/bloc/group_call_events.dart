// import 'package:defcomm/core/utils/call_manager.dart';
// import 'package:defcomm/features/group_calling/domain/usecase/start_group_call.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:videosdk/videosdk.dart';
// import '../../domain/repositories/group_call_repository.dart';

// abstract class GroupCallEvent {}
// class StartGroupCallRequested extends GroupCallEvent {
//   final String groupId;
//   final String displayName;
//   final String? meetingId;
//   StartGroupCallRequested({required this.groupId, required this.displayName, this.meetingId});
// }
// class GroupCallEndedEvent extends GroupCallEvent {}
// class ToggleGroupMuteEvent extends GroupCallEvent {}
// class ToggleGroupSpeakerEvent extends GroupCallEvent {}
// // (You can add RemoteParticipant events later)

// abstract class GroupCallState {}
// class GroupCallInitial extends GroupCallState {}
// class GroupCallConnecting extends GroupCallState {}
// class GroupCallConnected extends GroupCallState {
//   final Room room;
//   GroupCallConnected(this.room);
// }
// class GroupCallError extends GroupCallState {
//   final String message;
//   GroupCallError(this.message);
// }

// class GroupCallBloc extends Bloc<GroupCallEvent, GroupCallState> {
//   final StartGroupCall startGroupCall;
//   final GroupCallRepository repository;
//   final CallManager callManager;

//   Room? _room;

//   GroupCallBloc({required this.startGroupCall, required this.repository, required this.callManager}) : super(GroupCallInitial()) {
//     on<StartGroupCallRequested>(_onStart);
//     on<GroupCallEndedEvent>(_onEnded);
//     // optional: on<ToggleGroupMuteEvent>...
//   }

//   Future<void> _onStart(StartGroupCallRequested event, Emitter<GroupCallState> emit) async {
//     emit(GroupCallConnecting());
//     try {
//       final room = await startGroupCall.call(StartGroupCallParams(
//         groupId: event.groupId,
//         meetingId: event.meetingId,
//         displayName: event.displayName,
//         micEnabled: true,
//         camEnabled: false,
//       ));

//       _room = room;
//       try { callManager.startCall(); } catch (_) {}

//       // publish invite so group members get notified
//       await repository.publishGroupInvite(groupId: event.groupId, roomId: room.id ?? '');

//       emit(GroupCallConnected(room));

//       // attach participant join/leave/mute listeners here if you want
//       room.on(Events.participantJoined, (participant) {
//         debugPrint('participant joined: $participant');
//       });
//     } catch (e) {
//       emit(GroupCallError(e.toString()));
//     }
//   }

//   Future<void> _onEnded(GroupCallEndedEvent event, Emitter<GroupCallState> emit) async {
//     try { await _room?.leave(); } catch (_) {}
//     _room = null;
//     try { callManager.endCall(); } catch (_) {}
//     emit(GroupCallInitial());
//   }
// }
