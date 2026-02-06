import 'package:equatable/equatable.dart';

class GroupEntity extends Equatable {
  final String id;
  final String companyName;
  final String groupId;
  final String groupName;
  final String invitationDate;
  final String status;
  final bool isPending; 

   final int unreadCount; 

  const GroupEntity({
    required this.id,
    required this.companyName,
    required this.groupId,
    required this.groupName,
    required this.invitationDate,
    required this.status,
    required this.isPending,
    this.unreadCount = 0,
  });

  GroupEntity copyWith({
    String? id,
    String? companyName,
    String? groupId,
    String? groupName,
    String? invitationDate,
    String? status,
    bool? isPending,
    int? unreadCount,
  }) {
    return GroupEntity(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      invitationDate: invitationDate ?? this.invitationDate,
      status: status ?? this.status,
      isPending: isPending ?? this.isPending,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  List<Object?> get props => [id, groupId, groupName, unreadCount];
}