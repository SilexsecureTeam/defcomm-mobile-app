// group_call_repository_impl.dart
import 'package:defcomm/features/calling/domain/usecases/start_call.dart';
import 'package:defcomm/features/group_calling/core/group_call_constants.dart';
import 'package:defcomm/features/group_calling/data/datasources/group_call_remote_data_source.dart';
import 'package:defcomm/features/group_chat/domain/usecases/send_group_message.dart';
import 'package:videosdk/videosdk.dart';
import '../../domain/repositories/group_call_repository.dart';

class GroupCallRepositoryImpl implements GroupCallRepository {
  final GroupCallRemoteDataSource remote;
  final SendGroupMessage sendGroupMessageUseCase;
  final StartCall startCallUsecase; // reuse your 1:1 StartCall

  GroupCallRepositoryImpl({
    required this.remote,
    required this.sendGroupMessageUseCase,
    required this.startCallUsecase,
  });

  @override
  Future<Room> joinOrCreateGroupMeeting({
    required String groupId,
    String? meetingId,
    required String displayName,
    bool micEnabled = true,
    bool camEnabled = true,
  }) async {
    final id = meetingId ?? await remote.createMeeting();

    final room = await startCallUsecase.call(
      StartCallParams(
        meetingId: id,
        displayName: displayName,
        micEnabled: micEnabled,
        camEnabled: camEnabled,
      ),
    );

    return room;
  }

  @override
  Future<void> publishGroupInvite({required String groupId, required String roomId}) async {
    final msg = '$kGroupCallInvitePrefix$roomId';
    await sendGroupMessageUseCase(
      SendGroupMessageParams(
        message: msg,
        isFile: false,
        currentChatUser: groupId,
        mssType: 'call',
      ),
    );
  }

  @override
  Future<void> publishGroupEnded({required String groupId}) async {
    final msg = kGroupCallEnded;
    await sendGroupMessageUseCase(
      SendGroupMessageParams(
        message: msg,
        isFile: false,
        currentChatUser: groupId,
        mssType: 'call',
      ),
    );
  }

  @override
  Future<void> publishParticipantMute({
    required String groupId,
    required String participantId,
    required bool muted,
  }) async {
    final msg = (muted ? '$kGroupCallMute$participantId' : '$kGroupCallUnmute$participantId');
    await sendGroupMessageUseCase(
      SendGroupMessageParams(
        message: msg,
        isFile: false,
        currentChatUser: groupId,
        mssType: 'call',
      ),
    );
  }
}
