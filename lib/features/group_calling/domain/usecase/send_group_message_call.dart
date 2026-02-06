// // lib/features/group_chat/domain/usecases/send_group_message.dart

// import 'package:defcomm/features/group_chat/domain/entities/group_chat_message.dart';
// import 'package:defcomm/features/group_chat/domain/repositories/group_chat_repository.dart';
// import 'package:equatable/equatable.dart';
// import 'package:fpdart/fpdart.dart';

// import '../../../../core/error/failures.dart';
// import '../../../../core/usecase/usecase.dart';

// /// Params for sending a group message
// class SendGroupMessageParams extends Equatable {
//   /// encrypted group/user id (same as chat_user_id_en in the GET endpoint)
//   final String currentChatUser;
//   final String message;
//   final bool isFile;
//   final String mssType;          // "text", "call", "video"
//   final List<String> tagUserIds; // array of user ids
//   final String? tagMessageId;    // reply message id

//   const SendGroupMessageParams({
//     required this.currentChatUser,
//     required this.message,
//     required this.isFile,
//     this.mssType = 'call',
//     this.tagUserIds = const [],
//     this.tagMessageId,
//   });

//   @override
//   List<Object?> get props =>
//       [currentChatUser, message, isFile, mssType, tagUserIds, tagMessageId];
// }

// /// Use case wrapper – note `implements` instead of `extends`
// class SendGroupMessage
//     implements UseCase<GroupChatMessage, SendGroupMessageParams> {
//   final GroupChatRepository repository;

//   SendGroupMessage(this.repository);

//   @override
//   Future<Either<Failure, GroupChatMessage>> call(
//       SendGroupMessageParams params) {
//     return repository.sendGroupMessage(params);
//   }
// }
