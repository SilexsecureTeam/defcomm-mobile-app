import 'package:equatable/equatable.dart';

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
}

class ChatMessage extends Equatable {
  final String id;
  final bool isMyChat;
  final String senderId;
  final String? senderName;
  final String? recipientId;
  final String? recipientName;
  final String? message;
  final String? createdAt;
  final bool isFile;
  final bool isRead;

  final MessageStatus status;

  const ChatMessage({
    required this.id,
    required this.isMyChat,
    required this.senderId,
    this.senderName,
    this.recipientId,
    this.recipientName,
    this.message,
    this.createdAt,
    required this.isFile,
    required this.isRead,
    required this.status,
  });

  /// Create a ChatMessage from a server payload (Map).
  /// `currentUserId` is required so we can set `isMyChat` correctly.
  factory ChatMessage.fromMap(
    Map<String, dynamic> map, {
    required String currentUserId,
  }) {
    // Helper that safely reads nested sender object or plain id fields
    String _extractSenderId(Map<String, dynamic>? m) {
      if (m == null) return '';
      if (m['id'] != null) return m['id'].toString();
      if (m['user_id'] != null) return m['user_id'].toString();
      if (m['member_id_encrpt'] != null) return m['member_id_encrpt'].toString();
      return '';
    }

    final id = (map['id'] ??
            map['message_id'] ??
            map['msg_id'] ??
            map['uuid'] ??
            DateTime.now().millisecondsSinceEpoch.toString())
        .toString();

    // Some payloads wrap sender inside a 'sender' object, or use sender_id field
    String senderId = '';
    if (map['sender'] is Map) {
      senderId = _extractSenderId(Map<String, dynamic>.from(map['sender']));
    }
    if (senderId.isEmpty) {
      senderId = (map['sender_id'] ?? map['from'] ?? map['user_id'] ?? '').toString();
    }

    // recipient id
    String recipient = (map['recipient_id'] ?? map['to'] ?? map['user_to'] ?? map['receiver'] ?? '').toString();

    // message text
    final text = (map['message'] ?? map['body'] ?? map['text'] ?? '').toString();

    // created at
    final created = (map['created_at'] ?? map['createdAt'] ?? map['timestamp'] ?? DateTime.now().toIso8601String()).toString();

    // is file detection (some APIs return bool, some 'yes'/'no', some '1'/'0')
    bool isFile = false;
    final rawIsFile = map['is_file'] ?? map['file'] ?? map['isFile'];
    if (rawIsFile is bool) {
      isFile = rawIsFile;
    } else if (rawIsFile is String) {
      final s = rawIsFile.toLowerCase();
      isFile = s == 'yes' || s == 'true' || s == '1';
    } else if (rawIsFile is num) {
      isFile = rawIsFile != 0;
    }

    // isRead detection
    bool isRead = false;
    final rawIsRead = map['is_read'] ?? map['read'] ?? map['isRead'];
    if (rawIsRead is bool) {
      isRead = rawIsRead;
    } else if (rawIsRead is String) {
      final s = rawIsRead.toLowerCase();
      isRead = s == 'yes' || s == 'true' || s == '1';
    }

    // senderName & recipientName
    String? senderName;
    if (map['sender'] is Map && map['sender']['name'] != null) {
      senderName = map['sender']['name'].toString();
    } else if (map['sender_name'] != null) {
      senderName = map['sender_name'].toString();
    }

    String? recipientName;
    if (map['recipient_name'] != null) {
      recipientName = map['recipient_name'].toString();
    } else if (map['to_name'] != null) {
      recipientName = map['to_name'].toString();
    }

    // Determine whether this message was sent by current user
    final bool sentByMe = senderId.isNotEmpty ? (senderId == currentUserId) : false;
    

    return ChatMessage(
      id: id,
      isMyChat: sentByMe,
      senderId: senderId,
      senderName: senderName,
      recipientId: recipient.isNotEmpty ? recipient : null,
      recipientName: recipientName,
      message: text,
      createdAt: created,
      isFile: isFile,
      isRead: isRead,
      status: isRead ? MessageStatus.read : MessageStatus.sent,
      
      
      
    );
  }

  /// Convert to Map (useful for local cache or sending)
  Map<String, dynamic> toMap() => {
        'id': id,
        'is_my_chat': isMyChat ? 'yes' : 'no',
        'sender_id': senderId,
        'sender_name': senderName,
        'recipient_id': recipientId,
        'recipient_name': recipientName,
        'message': message,
        'created_at': createdAt,
        'is_file': isFile ? 'yes' : 'no',
        'is_read': isRead ? 'yes' : 'no',
      };

  ChatMessage copyWith({
    String? id,
    bool? isMyChat,
    String? senderId,
    String? senderName,
    String? recipientId,
    String? recipientName,
    String? message,
    String? createdAt,
    bool? isFile,
    bool? isRead,
    MessageStatus? status,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      isMyChat: isMyChat ?? this.isMyChat,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      recipientId: recipientId ?? this.recipientId,
      recipientName: recipientName ?? this.recipientName,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isFile: isFile ?? this.isFile,
      isRead: isRead ?? this.isRead,
      status: status ?? this.status,
      
    );
  }

  @override
  List<Object?> get props => [
        id,
        isMyChat,
        senderId,
        senderName,
        recipientId,
        recipientName,
        message,
        createdAt,
        isFile,
        isRead,
        status
      ];
}
