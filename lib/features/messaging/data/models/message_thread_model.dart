import '../../domain/entities/message_thread.dart';

class MessageThreadModel extends MessageThread {
  const MessageThreadModel({
    required super.id,
    required super.chatId,
    required super.chatUserToId,
    required super.chatUserId,
    required super.chatUserToName,
    required super.isFile,
    required super.lastMessage,
    required super.chatUserType,
    required super.imageUrl,
    required super.unRead
  });

  factory MessageThreadModel.fromJson(Map<String, dynamic> map) {
    return MessageThreadModel(
      id: map['id'] as String,
      chatId: map['chat_id'] as String?,
      chatUserToId: map['chat_user_to_id'] as String?,
      chatUserId: map['chat_user_id'] as String?,
      chatUserToName: map['chat_user_to_name'] as String?,
      isFile: map['is_file'] as String?,
      lastMessage: map['last_message'] as String?,
      chatUserType: map['chat_user_type'] as String?,
      
      imageUrl: 'images/defcomm_logo_1.png',
      unRead: map['unread'] as int?
    );
  }
}