import 'package:equatable/equatable.dart';

class MessageGroupEntity extends Equatable {
  final String id;
  final String companyName;
  final String groupId;
  final String groupName;
  final String invitationDate;
  final String status;
  final bool isPending; 

  const MessageGroupEntity({
    required this.id,
    required this.companyName,
    required this.groupId,
    required this.groupName,
    required this.invitationDate,
    required this.status,
    required this.isPending,
  });

  @override
  List<Object?> get props => [id, groupId, groupName];
}