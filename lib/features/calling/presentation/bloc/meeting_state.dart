part of 'call_cubit.dart';

/// Represents the current state of the meeting
class MeetingState extends Equatable {
  final bool isMicOff;
  final bool isVideoOff;
  final Map<String, Participant> participants;
  final Map<String, Stream?> participantVideoStreams;

  /// Creates a new immutable MeetingState instance
  const MeetingState({
    required this.isMicOff,
    required this.isVideoOff,
    required this.participants,
    required this.participantVideoStreams,
  });

  /// Creates a copy of the current state with updated values
  MeetingState copyWith({
    bool? isMicOff,
    bool? isVideoOff,
    Map<String, Participant>? participants,
    Map<String, Stream?>? participantVideoStreams,
  }) {
    return MeetingState(
      isMicOff: isMicOff ?? this.isMicOff,
      isVideoOff: isVideoOff ?? this.isVideoOff,
      participants: participants ?? this.participants,
      participantVideoStreams:
          participantVideoStreams ?? this.participantVideoStreams,
    );
  }

  /// Used by Equatable to compare state instances efficiently
  @override
  List<Object?> get props => [
    isMicOff,
    isVideoOff,
    participants,
    participantVideoStreams,
  ];
}
