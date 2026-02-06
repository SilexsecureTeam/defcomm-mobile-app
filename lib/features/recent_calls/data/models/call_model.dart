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

    return CallModel(
      id: id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : id,
      sendUserId: (json['send_user_id'] as String?) ?? '',
      sendUserName: (json['send_user_name'] as String?) ?? '',
      sendUserPhone: (json['send_user_phone'] as String?) ?? '',
      sendUserEmail: (json['send_user_email'] as String?)?.trim(),
      
      receiveUserId: (json['recieve_user_id'] ?? json['receive_user_id'])?.toString() ?? '',
      receiveUserName: (json['recieve_user_name'] ?? json['receive_user_name'])?.toString(),
      receiveUserPhone: (json['recieve_user_phone'] ?? json['receive_user_phone'])?.toString(),
      receiveUserEmail: (json['recieve_user_email'] ?? json['receive_user_email'])?.toString(),
      
      createdAtUtc: parsed.toUtc(),
      callState: (json['call_state'] as String?)?.trim() ?? 'unknown',
      callDurationSeconds: duration,
      chatBetween: (json['chatbtw'] ?? json['chat_between'])?.toString() ?? '',
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