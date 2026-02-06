import 'package:equatable/equatable.dart';

// abstract class CallEvent extends Equatable {
//   const CallEvent();

//   @override
//   List<Object?> get props => [];
// }

// class StartCallRequested extends CallEvent {
//   // final String token;
//   final String? meetingId;
//   final String displayName;
//   final bool micEnabled;
//   final bool camEnabled;

//   const StartCallRequested({
//     // required this.token,
//     this.meetingId,
//     required this.displayName,
//     this.micEnabled = true,
//     this.camEnabled = true,
//   });

//   @override
//   List<Object?> get props =>
//       [
//         // token, 
//         meetingId, displayName, micEnabled, camEnabled];
// }

// class CallEnded extends CallEvent {
//   const CallEnded();
// }

// class RemoteParticipantJoined extends CallEvent {
//   const RemoteParticipantJoined();

//   @override
//   List<Object?> get props => [];
// }


abstract class CallEvent extends Equatable {
  const CallEvent();

  @override
  List<Object?> get props => [];
}

class StartCallRequested extends CallEvent {
  final String? meetingId;
  final String displayName;
  final bool micEnabled;
  final bool camEnabled;

  const StartCallRequested({
    this.meetingId,
    required this.displayName,
    this.micEnabled = true,
    this.camEnabled = true,
  });

  @override
  List<Object?> get props => [meetingId, displayName, micEnabled, camEnabled];
}

class CallEnded extends CallEvent {
  const CallEnded();
}

// class RemoteParticipantJoined extends CallEvent {
//   const RemoteParticipantJoined();

//   @override
//   List<Object?> get props => [];
// }


