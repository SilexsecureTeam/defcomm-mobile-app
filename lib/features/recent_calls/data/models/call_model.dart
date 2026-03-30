import 'package:defcomm/features/recent_calls/domain/entities/call_entity.dart';

class CallModel {
  final String id;
  final String sendUserId;
  final String sendUserName;
  final String sendUserPhone;
  final String? sendUserEmail;
  final String receiveUserId;
  final String? receiveUserName;
  final String? receiveUserPhone;
  final String? receiveUserEmail;
  final DateTime createdAtUtc;
  final String callState;
  final int? callDurationSeconds;
  final String chatBetween;

  CallModel({
    required this.id,
    required this.sendUserId,
    required this.sendUserName,
    required this.sendUserPhone,
    this.sendUserEmail,
    required this.receiveUserId,
    this.receiveUserName,
    this.receiveUserPhone,
    this.receiveUserEmail,
    required this.createdAtUtc,
    required this.callState,
    this.callDurationSeconds,
    required this.chatBetween,
  });

  /// Parses a single item from GET /user/notification.
  /// Returns null if the item is not a call-type notification.
  static CallModel? fromNotification(Map<String, dynamic> json) {
    // Unwrap nested data field first (Laravel-style notification)
    Map<String, dynamic> flat = json;
    final inner = json['data'];
    if (inner is Map<String, dynamic>) {
      flat = {...json, ...inner};
    }

    // Only keep call-type entries.
    final type = (flat['type'] ?? flat['notification_type'] ?? '').toString().toLowerCase();
    final hasCallFields = flat.containsKey('call_state') ||
        flat.containsKey('send_user_name') ||
        flat.containsKey('caller_name') ||
        flat.containsKey('send_user_id') ||
        flat.containsKey('caller_id');
    final bool isCall = type.contains('call') || (type.isEmpty && hasCallFields);
    if (!isCall) return null;

    return CallModel.fromJson(flat);
  }

  factory CallModel.fromJson(Map<String, dynamic> json) {
    final id = (json['mss_id']?.toString() ?? json['id']?.toString() ?? '').trim();

    DateTime parsed;
    final createdAtRaw = json['created_at']; 

    if (createdAtRaw is String && createdAtRaw.isNotEmpty) {
      parsed = DateTime.tryParse(createdAtRaw) ?? DateTime.now().toUtc();
    } else if (createdAtRaw is DateTime) {
      parsed = createdAtRaw;
    } else {
      parsed = DateTime.now().toUtc();
    }

    int? duration;
    final dur = json['call_duration'];
    if (dur is int) {
      duration = dur;
    } else if (dur is String) {
      duration = int.tryParse(dur);
    }

    String _str(List<String> keys) {
      for (final k in keys) {
        final v = json[k];
        if (v != null) return v.toString().trim();
      }
      return '';
    }

    String? _strNullable(List<String> keys) {
      for (final k in keys) {
        final v = json[k];
        if (v != null) return v.toString().trim();
      }
      return null;
    }

    return CallModel(
      id: id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : id,
      sendUserId: _str(['send_user_id', 'sender_id', 'caller_id', 'user_id']),
      sendUserName: _str(['send_user_name', 'sender_name', 'caller_name', 'name']),
      sendUserPhone: _str(['send_user_phone', 'sender_phone', 'caller_phone', 'phone']),
      sendUserEmail: _strNullable(['send_user_email', 'sender_email', 'caller_email', 'email']),
      receiveUserId: _str(['recieve_user_id', 'receive_user_id', 'receiver_id', 'recipient_id']),
      receiveUserName: _strNullable(['recieve_user_name', 'receive_user_name', 'receiver_name', 'recipient_name']),
      receiveUserPhone: _strNullable(['recieve_user_phone', 'receive_user_phone', 'receiver_phone']),
      receiveUserEmail: _strNullable(['recieve_user_email', 'receive_user_email', 'receiver_email']),
      createdAtUtc: parsed.toUtc(),
      callState: _str(['call_state', 'status', 'call_type', 'call_status']).isEmpty
          ? 'unknown'
          : _str(['call_state', 'status', 'call_type', 'call_status']),
      callDurationSeconds: duration,
      chatBetween: _str(['chatbtw', 'chat_between', 'conversation_id']),
    );
  }

  CallEntity toEntity() {
    return CallEntity(
      id: id,
      sendUserId: sendUserId,
      sendUserName: sendUserName,
      sendUserPhone: sendUserPhone,
      sendUserEmail: sendUserEmail,
      receiveUserId: receiveUserId,
      receiveUserName: receiveUserName,
      receiveUserPhone: receiveUserPhone,
      receiveUserEmail: receiveUserEmail,
      createdAtUtc: createdAtUtc,
      callState: callState,
      callDurationSeconds: callDurationSeconds,
      chatBetween: chatBetween,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mss_id': id,
      'send_user_id': sendUserId,
      'send_user_name': sendUserName,
      'send_user_phone': sendUserPhone,
      'send_user_email': sendUserEmail,
            'recieve_user_id': receiveUserId,
      'recieve_user_name': receiveUserName,
      'recieve_user_phone': receiveUserPhone,
      'recieve_user_email': receiveUserEmail,
      
      'created_at': createdAtUtc.toIso8601String(),
      
      'call_state': callState,
      'call_duration': callDurationSeconds,
      'chatbtw': chatBetween,
    };
  }
}