// lib/features/group_call/presentation/bloc/group_call_bloc.dart

import 'dart:async';
import 'package:defcomm/core/utils/call_manager.dart';
import 'package:defcomm/features/group_calling/domain/usecase/start_group_call.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:videosdk/videosdk.dart'; 
import '../../domain/repositories/group_call_repository.dart';
import 'package:flutter/foundation.dart';

/// Simple participant model for UI
class GroupParticipant {
  final String id;
  final String name;
  final bool muted;
  GroupParticipant({required this.id, required this.name, this.muted = false});

  GroupParticipant copyWith({String? name, bool? muted}) {
    return GroupParticipant(id: id, name: name ?? this.name, muted: muted ?? this.muted);
  }
}

abstract class GroupCallEvent {}

class StartGroupCallRequested extends GroupCallEvent {
  final String groupId;
  final String displayName;
  final String? meetingId;
  StartGroupCallRequested({
    required this.groupId,
    required this.displayName,
    this.meetingId,
  });
}

class GroupCallEndedEvent extends GroupCallEvent {}

class RemoteParticipantJoinedEvent extends GroupCallEvent {
  final String participantId;
  final String displayName;
  RemoteParticipantJoinedEvent(this.participantId, this.displayName);
}

class RemoteParticipantLeftEvent extends GroupCallEvent {
  final String participantId;
  RemoteParticipantLeftEvent(this.participantId);
}

class RemoteParticipantMutedEvent extends GroupCallEvent {
  final String participantId;
  final bool muted;
  RemoteParticipantMutedEvent(this.participantId, this.muted);
}

class ToggleLocalMuteEvent extends GroupCallEvent {}

/// States
abstract class GroupCallState {}

class GroupCallInitial extends GroupCallState {}

class GroupCallConnecting extends GroupCallState {}

class GroupCallConnected extends GroupCallState {
  final Room room;
  final List<GroupParticipant> participants;
  final bool isMuted;
  final bool isSpeakerOn;

  GroupCallConnected({
    required this.room,
    this.participants = const [],
    this.isMuted = false,
    this.isSpeakerOn = false,
  });

  GroupCallConnected copyWith({
    Room? room,
    List<GroupParticipant>? participants,
    bool? isMuted,
    bool? isSpeakerOn,
  }) {
    return GroupCallConnected(
      room: room ?? this.room,
      participants: participants ?? this.participants,
      isMuted: isMuted ?? this.isMuted,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
    );
  }
}

class GroupCallError extends GroupCallState {
  final String message;
  GroupCallError(this.message);
}

/// Bloc
// class GroupCallBloc extends Bloc<GroupCallEvent, GroupCallState> {
//   final StartGroupCall startGroupCall;
//   final GroupCallRepository repository;
//   final CallManager callManager;
//   final String currentUserId; // pass this when registering bloc

//   Room? _room;
//   String? _activeGroupId;

//   GroupCallBloc({
//     required this.startGroupCall,
//     required this.repository,
//     required this.callManager,
//     required this.currentUserId,
//   }) : super(GroupCallInitial()) {
//     on<StartGroupCallRequested>(_onStartRequested);
//     on<GroupCallEndedEvent>(_onEnded);
//     on<RemoteParticipantJoinedEvent>(_onRemoteJoined);
//     on<RemoteParticipantLeftEvent>(_onRemoteLeft);
//     on<RemoteParticipantMutedEvent>(_onRemoteMuted);
//     on<ToggleLocalMuteEvent>(_onToggleLocalMute);
//   }

//   // Defensive extractor for participant info (works for Participant or Map)
//   Map<String, String> _extractParticipantInfo(dynamic p) {
//     try {
//       // If SDK provides a Participant object with id/displayName properties
//       final id = (p.id ?? p['id'] ?? p['participantId'] ?? p['participant_id']).toString();
//       String name = '';
//       // try common name fields
//       if (p is Map) {
//         name = (p['name'] ?? p['displayName'] ?? p['user_name'] ?? p['userName'] ?? '').toString();
//       } else {
//         // try object getters (may not exist depending on SDK)
//         try {
//           // ignore: avoid_dynamic_calls
//           name = (p.displayName ?? p.name ?? '').toString();
//         } catch (_) {
//           name = '';
//         }
//       }
//       if (name.isEmpty) name = 'Unknown';
//       return {'id': id, 'name': name};
//     } catch (e) {
//       // fallback generic
//       return {'id': (p?.toString() ?? 'unknown'), 'name': 'Unknown'};
//     }
//   }

//   Future<void> _onStartRequested(StartGroupCallRequested event, Emitter<GroupCallState> emit) async {
//     emit(GroupCallConnecting());

//     _activeGroupId = event.groupId;

//     try {
//       final room = await startGroupCall.call(StartGroupCallParams(
//         groupId: event.groupId,
//         meetingId: event.meetingId,
//         displayName: event.displayName,
//         micEnabled: true,
//         camEnabled: false,
//       ));

//       _room = room;

//       // Acquire global guard
//       try {
//         callManager.startCall();
//       } catch (_) {}

//       // Optionally publish invite: you may already publish invite before pushing UI.
//       try {
//         await repository.publishGroupInvite(groupId: event.groupId, roomId: room.id ?? '');
//       } catch (e) {
//         debugPrint('publishGroupInvite failed (non-fatal): $e');
//       }

//       // Attach listeners for participant join/leave (VideoSDK may give dynamic objects)
//       try {
//         _room?.on(Events.participantJoined, (dynamic p) {
//           final info = _extractParticipantInfo(p);
//           add(RemoteParticipantJoinedEvent(info['id']!, info['name']!));
//         });

//         _room?.on(Events.participantLeft, (dynamic p) {
//           final info = _extractParticipantInfo(p);
//           add(RemoteParticipantLeftEvent(info['id']!));
//         });
//       } catch (e) {
//         debugPrint('Warning: could not attach participant listeners: $e');
//       }

//       // Initial connected state: empty participants list (they'll arrive via events)
//       emit(GroupCallConnected(room: room, participants: [], isMuted: false, isSpeakerOn: false));
//     } catch (e) {
//       emit(GroupCallError(e.toString()));
//     }
//   }

//   Future<void> _onEnded(GroupCallEndedEvent event, Emitter<GroupCallState> emit) async {
//     try {
//       // publish ended control to group so others can close
//       if (_activeGroupId != null) {
//         try {
//           await repository.publishGroupEnded(groupId: _activeGroupId!);
//         } catch (_) {}
//       }
//     } catch (_) {}

//     try {
//       await _room?.leave();
//     } catch (e) {
//       debugPrint('Error leaving room: $e');
//     } finally {
//       _room = null;
//       _activeGroupId = null;
//       try {
//         callManager.endCall();
//       } catch (_) {}
//       emit(GroupCallInitial());
//     }
//   }

//   Future<void> _onRemoteJoined(RemoteParticipantJoinedEvent evt, Emitter<GroupCallState> emit) async {
//     final cur = state;
//     if (cur is GroupCallConnected) {
//       final List<GroupParticipant> p = List<GroupParticipant>.from(cur.participants);
//       final exists = p.any((x) => x.id == evt.participantId);
//       if (!exists) {
//         p.add(GroupParticipant(id: evt.participantId, name: evt.displayName, muted: false));
//         emit(cur.copyWith(participants: p));
//       }
//     }
//   }

//   Future<void> _onRemoteLeft(RemoteParticipantLeftEvent evt, Emitter<GroupCallState> emit) async {
//     final cur = state;
//     if (cur is GroupCallConnected) {
//       final List<GroupParticipant> p = List<GroupParticipant>.from(cur.participants)..removeWhere((x) => x.id == evt.participantId);
//       emit(cur.copyWith(participants: p));
//     }
//   }

//   Future<void> _onRemoteMuted(RemoteParticipantMutedEvent evt, Emitter<GroupCallState> emit) async {
//     final cur = state;
//     if (cur is GroupCallConnected) {
//       final List<GroupParticipant> p = List<GroupParticipant>.from(cur.participants);
//       final idx = p.indexWhere((x) => x.id == evt.participantId);
//       if (idx != -1) {
//         p[idx] = p[idx].copyWith(muted: evt.muted);
//       } else {
//         // if unknown participant, add them muted/unmuted
//         p.add(GroupParticipant(id: evt.participantId, name: 'Unknown', muted: evt.muted));
//       }
//       emit(cur.copyWith(participants: p));
//     }
//   }

//   Future<void> _onToggleLocalMute(ToggleLocalMuteEvent evt, Emitter<GroupCallState> emit) async {
//     final cur = state;
//     if (cur is! GroupCallConnected) return;
//     final bool newMuted = !cur.isMuted;

//     // 1) toggle local mic using SDK (method name may differ in your SDK)
//     try {
//       // try common method names — adapt to your SDK
//       if (_room != null) {
//         try {
//           // Many wrappers expose mute/unmute on Room or LocalParticipant
//           await _room!.muteMic();
//         } catch (_) {
//           try {
//             await _room!.localParticipant?.muteMic();
//           } catch (_) {
//             debugPrint('Could not call SDK mute method; adapt this to your VideoSDK wrapper');
//           }
//         }
//       }
//     } catch (e) {
//       debugPrint('Error toggling local mic: $e');
//     }

//     // 2) publish mute/unmute control to group so others update UI via Pusher
//     if (_activeGroupId != null) {
//       try {
//         await repository.publishParticipantMute(groupId: _activeGroupId!, participantId: currentUserId, muted: newMuted);
//       } catch (e) {
//         debugPrint('Failed to publish participant mute: $e');
//       }
//     }

//     // 3) locally update state so UI reflects immediately
//     if (cur is GroupCallConnected) {
//       emit(cur.copyWith(isMuted: newMuted));
//       // Also mark local participant in participants list if present
//       final List<GroupParticipant> p = List<GroupParticipant>.from(cur.participants);
//       final idx = p.indexWhere((x) => x.id == currentUserId);
//       if (idx != -1) {
//         p[idx] = p[idx].copyWith(muted: newMuted);
//         emit(cur.copyWith(participants: p, isMuted: newMuted));
//       }
//     }
//   }

//   @override
//   Future<void> close() {
//     try {
//       // detach listeners if needed — the SDK may provide remove/off variants
//     } catch (_) {}
//     return super.close();
//   }
// }


class GroupCallBloc extends Bloc<GroupCallEvent, GroupCallState> {
  final StartGroupCall startGroupCall;
  final GroupCallRepository repository;
  final CallManager callManager;
  final String currentUserId;

  Room? _room;
  String? _activeGroupId;

  GroupCallBloc({
    required this.startGroupCall,
    required this.repository,
    required this.callManager,
    required this.currentUserId,
  }) : super(GroupCallInitial()) {
    on<StartGroupCallRequested>(_onStartRequested);
    on<GroupCallEndedEvent>(_onEnded);
    on<RemoteParticipantJoinedEvent>(_onRemoteJoined);
    on<RemoteParticipantLeftEvent>(_onRemoteLeft);
    on<RemoteParticipantMutedEvent>(_onRemoteMuted);
    on<ToggleLocalMuteEvent>(_onToggleLocalMute);
  }

  GroupParticipant _mapSdkParticipantToModel(dynamic p) {
    String id = 'unknown';
    String name = 'Unknown';
    
    try {
      id = (p.id ?? p['id'] ?? p['participantId']).toString();
      name = (p.displayName ?? p.name ?? p['displayName'] ?? 'Unknown').toString();
    } catch (_) {}

    return GroupParticipant(id: id, name: name, muted: false); 
  }

  Future<void> _onStartRequested(StartGroupCallRequested event, Emitter<GroupCallState> emit) async {
    emit(GroupCallConnecting());

    _activeGroupId = event.groupId;

    try {
      final room = await startGroupCall.call(StartGroupCallParams(
        groupId: event.groupId,
        meetingId: event.meetingId,
        displayName: event.displayName,
        micEnabled: true,
        camEnabled: false,
      ));

      _room = room;

      try {
        callManager.startCall();
      } catch (_) {}

      if (event.meetingId == null) { 
         try {
           await repository.publishGroupInvite(groupId: event.groupId, roomId: room.id ?? '');
         } catch (e) {
           debugPrint('publishGroupInvite failed: $e');
         }
      }

      List<GroupParticipant> initialParticipants = [];
      try {
        if (room.participants != null && room.participants is Map) {
           final map = room.participants as Map;
           initialParticipants = map.values.map((p) => _mapSdkParticipantToModel(p)).toList();
        }
      } catch (e) {
        debugPrint("Could not load initial participants: $e");
      }

      try {
        _room?.on(Events.participantJoined, (dynamic p) {
          final part = _mapSdkParticipantToModel(p);
          add(RemoteParticipantJoinedEvent(part.id, part.name));
        });

        _room?.on(Events.participantLeft, (dynamic p) {
          final part = _mapSdkParticipantToModel(p);
          add(RemoteParticipantLeftEvent(part.id));
        });
        
        _room?.on(Events.micRequested, (dynamic p) { 
        });
      } catch (e) {
        debugPrint('Warning: could not attach listeners: $e');
      }

      emit(GroupCallConnected(
        room: room, 
        participants: initialParticipants, 
        isMuted: false, 
        isSpeakerOn: false
      ));
    } catch (e) {
      emit(GroupCallError("Connection failed: $e"));
    }
  }

  Future<void> _onToggleLocalMute(ToggleLocalMuteEvent evt, Emitter<GroupCallState> emit) async {
    final cur = state;
    if (cur is! GroupCallConnected) return;
    
    // Toggle logic
    final bool isNowMuted = !cur.isMuted;

    try {
      if (_room != null) {
        if (isNowMuted) {
           await _room!.muteMic(); 
        } else {
           await _room!.unmuteMic(); 
        }
      }
    } catch (e) {
      debugPrint('Error toggling mic: $e');
    }

    if (_activeGroupId != null) {
      repository.publishParticipantMute(
        groupId: _activeGroupId!, 
        participantId: currentUserId, 
        muted: isNowMuted
      );
    }

    emit(cur.copyWith(isMuted: isNowMuted));
  }

  Future<void> _onEnded(GroupCallEndedEvent event, Emitter<GroupCallState> emit) async {
    try {
      if (_activeGroupId != null) {
        await repository.publishGroupEnded(groupId: _activeGroupId!);
      }
      await _room?.leave();
      callManager.endCall();
    } catch (_) {}
    
    emit(GroupCallInitial());
  }

    Future<void> _onRemoteJoined(RemoteParticipantJoinedEvent evt, Emitter<GroupCallState> emit) async {
    final cur = state;
    if (cur is GroupCallConnected) {
      final List<GroupParticipant> p = List<GroupParticipant>.from(cur.participants);
      final exists = p.any((x) => x.id == evt.participantId);
      if (!exists) {
        p.add(GroupParticipant(id: evt.participantId, name: evt.displayName, muted: false));
        emit(cur.copyWith(participants: p));
      }
    }
  }

  Future<void> _onRemoteLeft(RemoteParticipantLeftEvent evt, Emitter<GroupCallState> emit) async {
    final cur = state;
    if (cur is GroupCallConnected) {
      final List<GroupParticipant> p = List<GroupParticipant>.from(cur.participants)..removeWhere((x) => x.id == evt.participantId);
      emit(cur.copyWith(participants: p));
    }
  }

  Future<void> _onRemoteMuted(RemoteParticipantMutedEvent evt, Emitter<GroupCallState> emit) async {
    final cur = state;
    if (cur is GroupCallConnected) {
      final List<GroupParticipant> p = List<GroupParticipant>.from(cur.participants);
      final idx = p.indexWhere((x) => x.id == evt.partsicipantId);
      if (idx != -1) {
        p[idx] = p[idx].copyWith(muted: evt.muted);
        emit(cur.copyWith(participants: p));
      }
    }
  }
}