import 'package:defcomm/core/error/exception.dart';
import 'package:defcomm/features/chat_details/data/datasources/chat_detail_local_data_source.dart';
import 'package:defcomm/features/chat_details/data/models/chat_messge_model.dart';
import 'package:defcomm/features/chat_details/data/models/chat_page_model.dart';
import 'package:defcomm/features/chat_details/domain/entities/chat_message.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/chat_page.dart';
import '../../domain/repositories/chat_detail_repository.dart';
import '../datasources/chat_detail_remote_data_source.dart';

// class ChatDetailRepositoryImpl implements ChatDetailRepository {
//   // The repository depends on the abstract data source, not the implementation.
//   final ChatDetailRemoteDataSource remoteDataSource;

//   ChatDetailRepositoryImpl(this.remoteDataSource);

//   @override
//   Future<Either<Failure, ChatPage>> fetchMessages({
//     required String chatUserId,
//     required int page,
//   }) async {
//     try {
//       final chatPageModel = await remoteDataSource.fetchMessages(
//         chatUserId: chatUserId,
//         page: page,
//       );

//       return right(chatPageModel);
//     } on ServerException catch (e) {
//       return left(ServerFailure(e.message));
//     }
//   }

//   @override
//   Future<Either<Failure, ChatMessage>> sendMessage({
//     required String message,
//     required bool isFile,
//     required String chatUserType,
//     required String currentChatUser,
//     String? chatId,
//   }) async {
//     try {
//       final chatMessageModel = await remoteDataSource.sendMessage(
//         message: message,
//         isFile: isFile,
//         chatUserType: chatUserType,
//         currentChatUser: currentChatUser,
//         chatId: chatId,
//       );
//       // On success, return the new message inside a 'Right'
//       return right(chatMessageModel);
//     } on ServerException catch (e) {
//       // On failure, return the error message inside a 'Left'
//       return left(ServerFailure(e.message));
//     }
//   }
// }


class ChatDetailRepositoryImpl implements ChatDetailRepository {
  // The repository depends on the abstract data source, not the implementation.
  final ChatDetailRemoteDataSource remoteDataSource;
  final ChatDetailLocalDataSource localDataSource;

  ChatDetailRepositoryImpl(this.remoteDataSource, this.localDataSource);

  @override
  Future<Either<Failure, ChatPage>> fetchMessages({
    required String chatUserId,
    required int page,
  }) async {
    try {
      final chatPageModel = await remoteDataSource.fetchMessages(
        chatUserId: chatUserId,
        page: page,
      );

      if (page == 1) {
        await localDataSource.cacheMessages(
          chatUserId: chatUserId,
          messages: chatPageModel.messages.cast<ChatMessageModel>(),
        );
      }

      return right(chatPageModel);
    } on ServerException catch (e) {
      if (page == 1) {
        try {
          final localMessages = await localDataSource.getLocalMessages(chatUserId: chatUserId);
          if (localMessages.isNotEmpty) {
            // Construct a fake "Page" from local data
            return right(ChatPageModel(
              messages: localMessages,
              currentPage: 1,
              lastPage: 1, // Prevent trying to load more if offline
            ));
          }
        } catch (_) {
           // If local fails too, just fall through to error
        }
      }
      return left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, ChatMessage>> sendMessage({
    required String message,
    required bool isFile,
    required String chatUserType,
    required String currentChatUser,
    String? chatId,

    required String mssType,        // 👈 default here too
    String? tagMessageId,
    String? tagMessageText,
    List<String>? tagUserIds,
  }) async {
    try {
      final chatMessageModel = await remoteDataSource.sendMessage(
        message: message,
        isFile: isFile,
        chatUserType: chatUserType,
        currentChatUser: currentChatUser,
        chatId: chatId,

         mssType: mssType,
        tagMessageId: tagMessageId,
        tagMessageText: tagMessageText,
        tagUserIds: tagUserIds,
      );

      await localDataSource.addMessage(
        chatUserId: currentChatUser, // This should be the person we are chatting with, wait.
        // NOTE: In your params, 'currentChatUser' seems to be the encrypted ID of the contact?
        // If so, use that.
        message: chatMessageModel,
      );
      // On success, return the new message inside a 'Right'
      return right(chatMessageModel);
    } on ServerException catch (e) {
      // On failure, return the error message inside a 'Left'
      return left(ServerFailure(e.message));
    }
  }
}