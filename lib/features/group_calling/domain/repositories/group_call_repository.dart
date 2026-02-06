import 'package:videosdk/videosdk.dart';

abstract class GroupCallRepository {
  Future<Room> joinOrCreateGroupMeeting({
    required String groupId,
    String? meetingId,
    required String displayName,
    bool micEnabled,
    bool camEnabled,
  });

  Future<void> publishGroupInvite({required String groupId, required String roomId});
  Future<void> publishGroupEnded({required String groupId});
  Future<void> publishParticipantMute({required String groupId, required String participantId, required bool muted});
}
