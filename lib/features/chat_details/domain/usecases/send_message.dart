import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/chat_message.dart';
import '../repositories/chat_detail_repository.dart';

// class SendMessage implements UseCase<ChatMessage, SendMessageParams> {
//   final ChatDetailRepository repository;
//   SendMessage(this.repository);

//   @override
//   Future<Either<Failure, ChatMessage>> call(SendMessageParams params) async {
//     return await repository.sendMessage(
//       message: params.message,
//       isFile: params.isFile,
//       chatUserType: params.chatUserType,
//       currentChatUser: params.currentChatUser,
//       chatId: params.chatId,
//     );
//   }
// }

// class SendMessageParams {
//   final String message;
//   final bool isFile;
//   final String chatUserType;
//   final String currentChatUser;
//   final String? chatId;

//   SendMessageParams({
//     required this.message,
//     required this.isFile,
//     required this.chatUserType,
//     required this.currentChatUser,
//     this.chatId,
//   });
// }

class SendMessage implements UseCase<ChatMessage, SendMessageParams> {
  final ChatDetailRepository repository;
  SendMessage(this.repository);

  @override
  Future<Either<Failure, ChatMessage>> call(SendMessageParams params) async {
    return await repository.sendMessage(
      message: params.message,
      isFile: params.isFile,
      chatUserType: params.chatUserType,
      currentChatUser: params.currentChatUser,
      chatId: params.chatId,

      // 🔽 NEW
      mssType: params.mssType,
      tagMessageId: params.tagMessageId,
      tagMessageText: params.tagMessageText,
      tagUserIds: params.tagUserIds,
    );
  }
}

class SendMessageParams {
  final String message;
  final bool isFile;
  final String chatUserType;    // 'user' | 'group'
  final String currentChatUser; // encrypted id
  final String? chatId;

  /// NEW: backend mss_type field ('text', 'call', 'video', etc.)
  final String mssType;

  /// Optional tagging (reply / @mentions)
  final String? tagMessageId;       // tag_mess_id
  final String? tagMessageText;     // tag_mess
  final List<String>? tagUserIds;   // tag_user[]

  SendMessageParams({
    required this.message,
    required this.isFile,
    required this.chatUserType,
    required this.currentChatUser,
    this.chatId,
    this.mssType = 'text',         // 👈 default so old usages stay text
    this.tagMessageId,
    this.tagMessageText,
    this.tagUserIds,
  });
}