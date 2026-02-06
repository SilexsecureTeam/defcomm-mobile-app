import 'package:defcomm/features/groups/domain/entities/group_entity.dart';
import 'package:defcomm/features/messaging/domain/entities/message_group_entity.dart';
import 'package:equatable/equatable.dart';

class MessageGroupModel extends Equatable {
  final String id;
  final String? companyName;
  final String? groupId;
  final String? groupName;
  final String? joinDate;
  final String? invitationDate;
  final String? status;
  final bool? hideMyDetail;

  const MessageGroupModel({
    required this.id,
     this.companyName,
     this.groupId,
     this.groupName,
    this.joinDate,
     this.invitationDate,
     this.status,
     this.hideMyDetail,
  });

  factory MessageGroupModel.fromJson(Map<String, dynamic> map) {
    return MessageGroupModel(
      id: map['id'] as String,
      companyName: map['company_name'] as String?,
      groupId: map['group_id'] as String?,
      groupName: map['group_name'] as String?,
      joinDate: map['join_date'] as String?,
      invitationDate: map['invitation_date'] as String?,
      status: map['status'] as String?,
      hideMyDetail: (map['hide_my_detail'] as String?)?.toLowerCase() == 'yes',
    );
  }

   Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company_name': companyName,
      'group_id': groupId,
      'group_name': groupName,
      'join_date': joinDate,
      'invitation_date': invitationDate,
      'status': status,
      'hide_my_detail': hideMyDetail == true ? 'yes' : 'no',
    };
  }

  GroupEntity toEntity() {
    final safeStatus = status ?? "unknown";
    return GroupEntity(
      id: id,
      companyName: companyName ?? "",
      groupId: groupId ?? "",
      groupName: groupName ?? "",
      invitationDate: invitationDate ?? "",
      status: status ?? "",
      isPending: status!.toLowerCase() != 'joined',
      unreadCount: 0, 
    );
  }

  @override
  List<Object?> get props => [id, groupId, groupName];
}