import 'package:videosdk/videosdk.dart';

/// Abstraction for joining / creating a VideoSDK meeting.
abstract class CallRepository {
  /// If [meetingId] is null or empty, a new meeting is created.
  /// Otherwise, it joins the given meeting.
  Future<Room> joinOrCreateMeeting({
    String? meetingId,
    required String displayName,
    bool micEnabled,
    bool camEnabled,
  });

  Future<String> createMeetingId(); 
}
