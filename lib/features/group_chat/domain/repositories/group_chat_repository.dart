import 'package:defcomm/features/group_chat/domain/entities/group_chat_message.dart';
import 'package:defcomm/features/group_chat/domain/usecases/send_group_message.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/group_chat_page.dart';

abstract class GroupChatRepository {
  Future<Either<Failure, GroupChatPage>> fetchGroupMessages({
    required String groupUserIdEn,
    required int page,
  });

   Future<Either<Failure, GroupChatMessage>> sendGroupMessage(
    SendGroupMessageParams params,
  );
}
