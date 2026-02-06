// lib/features/group_chat/domain/usecases/send_group_message.dart

import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/group_chat_message.dart';
import '../repositories/group_chat_repository.dart';

class SendGroupMessageParams extends Equatable {
  final String currentChatUser;
  final String message;
  final bool isFile;
  final String mssType;          // "text", "call", "video"
  final List<String> tagUserIds; // array of user ids
  final String? tagMessageId;    // reply message id

  const SendGroupMessageParams({
    required this.currentChatUser,
    required this.message,
    required this.isFile,
    this.mssType = 'text',
    this.tagUserIds = const [],
    this.tagMessageId,
  });

  @override
  List<Object?> get props =>
      [currentChatUser, message, isFile, mssType, tagUserIds, tagMessageId];
}

/// Use case wrapper – note `implements` instead of `extends`
class SendGroupMessage
    implements UseCase<GroupChatMessage, SendGroupMessageParams> {
  final GroupChatRepository repository;

  SendGroupMessage(this.repository);

  @override
  Future<Either<Failure, GroupChatMessage>> call(
      SendGroupMessageParams params) {
    return repository.sendGroupMessage(params);
  }
}
