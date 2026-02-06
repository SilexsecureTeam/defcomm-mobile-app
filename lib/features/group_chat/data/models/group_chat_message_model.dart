import '../../domain/entities/group_chat_message.dart';

class GroupChatMessageModel extends GroupChatMessage {
  const GroupChatMessageModel({
    required super.id,
    required super.isMyChat,
    required super.senderId,
    required super.senderName,
    super.groupId,
    super.message,
    required super.createdAt,
    required super.isFile,
    required super.isRead,
    super.fileType,
    super.tagUserId,
    super.tagMessageId,
    super.tagMessageUserId,
    super.tagMessageIsMyChat,
    super.tagMessageText,
  });

  factory GroupChatMessageModel.fromJson(Map<String, dynamic> json) {
    final isMyChat =
        (json['is_my_chat'] as String?)?.toLowerCase() == 'yes';

    bool toBool(dynamic v) {
      if (v == null) return false;
      if (v is bool) return v;
      if (v is String) {
        final s = v.toLowerCase();
        return s == 'yes' || s == 'true' || s == '1';
      }
      if (v is num) return v != 0;
      return false;
    }

    return GroupChatMessageModel(
      id: json['id']?.toString() ?? '',
      isMyChat: isMyChat,
      senderId: json['user_id']?.toString() ?? '',
      senderName: json['user_name']?.toString() ?? 'Unknown',
      groupId: json['group_to']?.toString(),
      message: json['message']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      isFile: toBool(json['is_file']),
      isRead: toBool(json['is_read']),
      fileType: json['file_type']?.toString(),
      tagUserId: json['tag_user']?.toString(),
      tagMessageId: json['tag_mess_id']?.toString(),
      tagMessageUserId: json['tag_mess_user']?.toString(),
      tagMessageIsMyChat:
          (json['tag_mess_is_my_chat'] as String?)
              ?.toLowerCase() ==
          'yes',
      tagMessageText: json['tag_mess']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'is_my_chat': isMyChat ? 'yes' : 'no', 
      'user_id': senderId,
      'user_name': senderName,
      'group_to': groupId,
      'message': message,
      'created_at': createdAt,
      'is_file': isFile ? 'yes' : 'no',
      'is_read': isRead ? 'yes' : 'no',
      'file_type': fileType,
      'tag_user': tagUserId,
      'tag_mess_id': tagMessageId,
      'tag_mess_user': tagMessageUserId,
      'tag_mess_is_my_chat': (tagMessageIsMyChat ?? false) ? 'yes' : 'no',
      'tag_mess': tagMessageText,
    };
  }
}
