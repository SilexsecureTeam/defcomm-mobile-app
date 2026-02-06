// import 'package:equatable/equatable.dart';

// class GroupParticipant extends Equatable {
//   final String id;
//   final String name;
//   final bool muted;
//   GroupParticipant({required this.id, required this.name, this.muted = false});
//   GroupParticipant copyWith({bool? muted, String? name}) =>
//       GroupParticipant(id: id, name: name ?? this.name, muted: muted ?? this.muted);
//   @override List<Object?> get props => [id, name, muted];
// }

// abstract class GroupCallState extends Equatable {
//   const GroupCallState();
//   @override List<Object?> get props => [];
// }

// class GroupCallInitial extends GroupCallState {}

// class GroupCallDialing extends GroupCallState {
//   final String roomId;
//   final List<GroupParticipant> participants;
//   const GroupCallDialing({required this.roomId, this.participants = const []});
//   @override List<Object?> get props => [roomId, participants];
// }

// class GroupCallInProgress extends GroupCallState {
//   final String roomId;
//   final List<GroupParticipant> participants;
//   final bool isMuted;
//   final bool isSpeakerOn;
//   const GroupCallInProgress({
//     required this.roomId,
//     this.participants = const [],
//     this.isMuted = false,
//     this.isSpeakerOn = false,
//   });
//   @override List<Object?> get props => [roomId, participants, isMuted, isSpeakerOn];
// }

// class GroupCallError extends GroupCallState {
//   final String message;
//   const GroupCallError(this.message);
//   @override List<Object?> get props => [message];
// }
