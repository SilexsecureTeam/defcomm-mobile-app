import 'package:defcomm/features/chat_details/domain/entities/chat_message.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/chat_page.dart';

abstract interface class ChatDetailRepository {
  Future<Either<Failure, ChatPage>> fetchMessages({
    required String chatUserId,
    required int page,
  });

  Future<Either<Failure, ChatMessage>> sendMessage({
    required String message,
    required bool isFile,
    required String chatUserType,
    required String currentChatUser,
    String? chatId,

    // 🔽 NEW
    required String mssType,                 // default will be handled in impl
    String? tagMessageId,
    String? tagMessageText,
    List<String>? tagUserIds,
  });
}