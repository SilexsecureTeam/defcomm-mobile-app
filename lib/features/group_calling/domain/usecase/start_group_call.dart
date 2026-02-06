import 'package:videosdk/videosdk.dart';
import '../repositories/group_call_repository.dart';

class StartGroupCallParams {
  final String groupId;
  final String? meetingId; 
  final String displayName;
  final bool micEnabled;
  final bool camEnabled;

  const StartGroupCallParams({
    required this.groupId,
    this.meetingId,
    required this.displayName,
    this.micEnabled = true,
    this.camEnabled = true,
  });
}

class StartGroupCall {
  final GroupCallRepository repository;
  StartGroupCall(this.repository);

  Future<Room> call(StartGroupCallParams params) {
    return repository.joinOrCreateGroupMeeting(
      groupId: params.groupId,
      meetingId: params.meetingId,
      displayName: params.displayName,
      micEnabled: params.micEnabled,
      camEnabled: params.camEnabled,
    );
  }
}
