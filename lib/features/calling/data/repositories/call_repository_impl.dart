import 'package:defcomm/core/constants/base_url.dart';
import 'package:defcomm/features/calling/data/datasources/call_remote_data_source.dart';
import 'package:videosdk/videosdk.dart';

import '../../domain/repositories/call_repository.dart';


class CallRepositoryImpl implements CallRepository {
  final CallRemoteDataSource remoteDataSource;

  CallRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Room> joinOrCreateMeeting({
    String? meetingId,
    required String displayName,
    bool micEnabled = true,
    bool camEnabled = true,
  }) async {
    final String roomId = (meetingId == null || meetingId.isEmpty)
        ? await remoteDataSource.createMeeting()
        : meetingId;

    final room = VideoSDK.createRoom(
      roomId: roomId,        // 👈 deterministic id from our helper
      token: videoDevTokenKey,  // dev token
      displayName: displayName,
      micEnabled: micEnabled,
      camEnabled: camEnabled,
    );

    room.join();
    return room;
  }

  @override
  Future<String> createMeetingId() async {
    return await remoteDataSource.createMeeting();
  }
}


