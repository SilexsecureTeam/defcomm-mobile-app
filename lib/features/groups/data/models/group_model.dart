import 'package:equatable/equatable.dart';
import '../../domain/entities/group_entity.dart';

class GroupModel extends Equatable {
  final String id;
  final String? companyName;
  final String? groupId;
  final String? groupName;
  final String? joinDate;
  final String? invitationDate;
  final String? status;
  final bool? hideMyDetail;

  const GroupModel({
    required this.id,
     this.companyName,
     this.groupId,
     this.groupName,
    this.joinDate,
     this.invitationDate,
     this.status,
     this.hideMyDetail,
  });

  factory GroupModel.fromJson(Map<String, dynamic> map) {
    return GroupModel(
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

  // A handy method to convert the Data Model to a Domain Entity
  GroupEntity toEntity() {
    return GroupEntity(
      id: id,
      companyName: companyName ?? "",
      groupId: groupId ?? "",
      groupName: groupName ?? "",
      invitationDate: invitationDate ?? "",
      status: status ?? "",
      isPending: status!.toLowerCase() != 'joined',
    );
  }

  @override
  List<Object?> get props => [id, groupId, groupName];
}