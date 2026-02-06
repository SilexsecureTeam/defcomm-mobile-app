import 'package:equatable/equatable.dart';

class GroupChatMessage extends Equatable {
  final String id;
  final bool isMyChat;
  final String senderId;
  final String senderName;

  final String? groupId;          
  final String? message;
  final String createdAt;

  final bool isFile;
  final bool isRead;
  final String? fileType;

  // Tagging
  final String? tagUserId;        // tag_user
  final String? tagMessageId;     // tag_mess_id
  final String? tagMessageUserId; // tag_mess_user
  final bool? tagMessageIsMyChat; // tag_mess_is_my_chat
  final String? tagMessageText;   // tag_mess

  const GroupChatMessage({
    required this.id,
    required this.isMyChat,
    required this.senderId,
    required this.senderName,
    this.groupId,
    this.message,
    required this.createdAt,
    required this.isFile,
    required this.isRead,
    this.fileType,
    this.tagUserId,
    this.tagMessageId,
    this.tagMessageUserId,
    this.tagMessageIsMyChat,
    this.tagMessageText,
  });

  @override
  List<Object?> get props => [
        id,
        isMyChat,
        senderId,
        senderName,
        groupId,
        message,
        createdAt,
        isFile,
        isRead,
        fileType,
        tagUserId,
        tagMessageId,
        tagMessageUserId,
        tagMessageIsMyChat,
        tagMessageText,
      ];
}
