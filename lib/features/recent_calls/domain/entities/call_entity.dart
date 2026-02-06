import 'package:equatable/equatable.dart';

class CallEntity extends Equatable {
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
  final String chatBetween; // chatbtw

  const CallEntity({
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

  @override
  List<Object?> get props => [
        id,
        sendUserId,
        sendUserName,
        sendUserPhone,
        sendUserEmail,
        receiveUserId,
        receiveUserName,
        receiveUserPhone,
        receiveUserEmail,
        createdAtUtc,
        callState,
        callDurationSeconds,
        chatBetween,
      ];
}
