import '../../domain/entities/chat_message.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.isMyChat,
    required super.senderId,
    super.senderName,
    super.recipientId,
    super.recipientName,
    super.message,
    super.createdAt,
    required super.isFile,
    required super.isRead,
    required super.status,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> map) {
    // 1. Handle Boolean Strings safely (API 'yes'/'no' vs Local 'yes'/'no' vs boolean)
    bool isMyChatFlag = false;
    if (map['is_my_chat'] is bool) {
      isMyChatFlag = map['is_my_chat'];
    } else {
      isMyChatFlag = (map['is_my_chat'] as String?)?.toLowerCase() == 'yes';
    }

    bool isFileFlag = false;
    if (map['is_file'] is bool) {
      isFileFlag = map['is_file'];
    } else {
      isFileFlag = (map['is_file'] as String?)?.toLowerCase() == 'yes';
    }

    bool isReadFlag = false;
    if (map['is_read'] is bool) {
      isReadFlag = map['is_read'];
    } else {
      isReadFlag = (map['is_read'] as String?)?.toLowerCase() == 'yes';
    }

    // 2. Safely extract ID (could be int or string from API)
    final String id = map['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();

    // 3. Handle Key Variations (API vs Local Storage)
    
    // SENDER ID: API uses 'user_id', Local uses 'sender_id'
    final String senderId = (map['user_id'] ?? map['sender_id'])?.toString() ?? '';

    // SENDER NAME: API uses 'user_name', Local uses 'sender_name'
    final String? senderName = map['user_name'] ?? map['sender_name'];

    // RECIPIENT ID: API uses 'user_to', Local uses 'recipient_id'
    final String? recipientId = (map['user_to'] ?? map['recipient_id'])?.toString();

    // RECIPIENT NAME: API uses 'user_to_name', Local uses 'recipient_name'
    final String? recipientName = map['user_to_name'] ?? map['recipient_name'];

    return ChatMessageModel(
      id: id,
      isMyChat: isMyChatFlag,
      senderId: senderId,
      senderName: senderName,
      recipientId: recipientId,
      recipientName: recipientName,
      message: map['message']?.toString(),
      createdAt: map['created_at']?.toString(),
      isFile: isFileFlag,
      isRead: isReadFlag,
      status: isReadFlag ? MessageStatus.read : MessageStatus.sent,
    );
  }
}
