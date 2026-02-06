import 'package:videosdk/videosdk.dart';
import '../repositories/call_repository.dart';

class StartCallParams {
  // final String token;          // your VideoSDK auth token
  final String? meetingId;     // null => create new
  final String displayName;
  final bool micEnabled;
  final bool camEnabled;

  const StartCallParams({
    // required this.token,
    this.meetingId,
    required this.displayName,
    this.micEnabled = true,
    this.camEnabled = true,
  });
}

class StartCall {
  final CallRepository repository;

  StartCall(this.repository);

  Future<Room> call(StartCallParams params) {
    return repository.joinOrCreateMeeting(
      meetingId: params.meetingId,
      displayName: params.displayName,
      micEnabled: params.micEnabled,
      camEnabled: params.camEnabled,
    );
  }
}
