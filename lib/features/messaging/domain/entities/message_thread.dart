import 'package:equatable/equatable.dart';

// class MessageThread extends Equatable {
//   final String id;
//   final String? chatId;
//   final String? chatUserToId;
//   final String? chatUserId;
//   final String? chatUserToName;
//   final String? isFile;
//   final String? lastMessage;
//   final String? chatUserType;
//   final String imageUrl;

//   const MessageThread({
//     required this.id,
//     required this.chatId,
//     required this.chatUserToId,
//     required this.chatUserId,
//     required this.chatUserToName,
//     required this.isFile,
//     required this.lastMessage,
//     required this.chatUserType,
//     required this.imageUrl,
//   });

//   @override
//   List<Object?> get props => [
//         id,
//         chatId,
//         chatUserToId,
//         chatUserId,
//         chatUserToName,
//         isFile,
//         lastMessage,
//         chatUserType,
//         imageUrl,
//       ];
// }

import 'package:equatable/equatable.dart';

class MessageThread extends Equatable {
  final String id;
  final String? chatId;
  final String? chatUserToId;
  final String? chatUserId;
  final String? chatUserToName;
  final String? isFile;
  final String? lastMessage;
  final String? chatUserType;
  final String imageUrl;
  final int? unRead;

   final bool isTyping;

  const MessageThread({
    required this.id,
    required this.chatId,
    required this.chatUserToId,
    required this.chatUserId,
    required this.chatUserToName,
    required this.isFile,
    required this.lastMessage,
    required this.chatUserType,
    required this.imageUrl,
    required this.unRead,

    this.isTyping = false,

  });

  factory MessageThread.fromMap(Map<String, dynamic> m) {
    String _extractId(dynamic v) {
      if (v == null) return '';
      return v.toString();
    }

    final String id =
        _extractId(m['conversation_id'] ?? m['chat_id'] ?? m['id'] ?? DateTime.now().millisecondsSinceEpoch);

    final String? chatId = m['chat_id']?.toString();

    final String? chatUserId =
        m['chat_user_id']?.toString() ?? m['user_id']?.toString();

    final String? chatUserToId =
        m['chat_user_to_id']?.toString() ?? m['user_to']?.toString();

    final String? chatUserToName = m['chat_user_to_name']?.toString() ??
        m['to_name']?.toString() ??
        m['sender']?['name']?.toString();

    final String? lastMessage = m['last_message']?.toString() ??
        m['message']?.toString() ??
        m['body']?.toString();

    String? isFile = m['is_file']?.toString() ?? m['file']?.toString();
    if (isFile != null) isFile = isFile.trim();

    final String? chatUserType = m['chat_user_type']?.toString() ?? m['type']?.toString();

     final int? unRead = m['unread'];

    final String imageUrl = m['avatar']?.toString() ??
        m['image']?.toString() ??
        'images/defcomm_logo_1.png';

    return MessageThread(
      id: id,
      chatId: chatId,
      chatUserToId: chatUserToId,
      chatUserId: chatUserId,
      chatUserToName: chatUserToName,
      isFile: isFile,
      lastMessage: lastMessage,
      chatUserType: chatUserType,
      imageUrl: imageUrl,
      unRead: unRead
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'chat_id': chatId,
        'chat_user_to_id': chatUserToId,
        'chat_user_id': chatUserId,
        'chat_user_to_name': chatUserToName,
        'is_file': isFile,
        'last_message': lastMessage,
        'chat_user_type': chatUserType,
        'imageUrl': imageUrl,
        "unread": unRead
      };

  MessageThread copyWith({
    String? id,
    String? chatId,
    String? chatUserToId,
    String? chatUserId,
    String? chatUserToName,
    String? isFile,
    String? lastMessage,
    String? chatUserType,
    String? imageUrl,
    int? unRead,

    bool? isTyping,
  }) {
    return MessageThread(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      chatUserToId: chatUserToId ?? this.chatUserToId,
      chatUserId: chatUserId ?? this.chatUserId,
      chatUserToName: chatUserToName ?? this.chatUserToName,
      isFile: isFile ?? this.isFile,
      lastMessage: lastMessage ?? this.lastMessage,
      chatUserType: chatUserType ?? this.chatUserType,
      imageUrl: imageUrl ?? this.imageUrl,
      unRead: unRead ?? this.unRead,

      isTyping: isTyping ?? this.isTyping,
    );
  }

  @override
  List<Object?> get props => [
        id,
        chatId,
        chatUserToId,
        chatUserId,
        chatUserToName,
        isFile,
        lastMessage,
        chatUserType,
        imageUrl,
        unRead,
        isTyping
      ];
}
