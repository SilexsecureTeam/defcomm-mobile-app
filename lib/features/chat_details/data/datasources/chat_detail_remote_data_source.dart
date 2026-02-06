import 'package:defcomm/features/chat_details/data/models/chat_messge_model.dart';

import '../models/chat_page_model.dart';

// abstract interface class ChatDetailRemoteDataSource {

//   Future<ChatPageModel> fetchMessages({
//     required String chatUserId,
//     required int page,
//   });

//   Future<ChatMessageModel> sendMessage({
//     required String message,
//     required bool isFile,
//     required String chatUserType,
//     required String currentChatUser,
//     String? chatId,
//   });
// }

abstract interface class ChatDetailRemoteDataSource {
  Future<ChatPageModel> fetchMessages({
    required String chatUserId,
    required int page,
  });

  Future<ChatMessageModel> sendMessage({
    required String message,
    required bool isFile,
    required String chatUserType,
    required String currentChatUser,
    String? chatId,

    // 🔽 NEW
    required String mssType,
    String? tagMessageId,
    String? tagMessageText,
    List<String>? tagUserIds,
  });
}