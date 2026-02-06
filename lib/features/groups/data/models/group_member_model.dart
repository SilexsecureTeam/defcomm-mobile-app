class GroupMemberModel {
  final String id;
  final String? joinDate;
  final String? hideMemberDetail;
  final String? memberIdEncrypt;
  final int? memberId;
  final String? memberName;

  final String? companyId;
  final String? groupName;
  final String? description;

  GroupMemberModel({
    required this.id,
    this.joinDate,
    this.hideMemberDetail,
    this.memberIdEncrypt,
    this.memberId,
    this.memberName,
    this.companyId,
    this.groupName,
    this.description,
  });

  factory GroupMemberModel.fromJson(
    Map<String, dynamic> map,
    Map<String, dynamic>? groupMeta,
  ) {
    return GroupMemberModel(
      id: map['id'] as String,
      joinDate: map['join_date'] as String?,
      hideMemberDetail: map['hide_member_detail'] as String?,
      memberIdEncrypt: map['member_id_encrpt'] as String?,
      memberId: map['member_id'] is int ? map['member_id'] : int.tryParse("${map['member_id']}"),
      memberName: map['member_name'] as String?,

      companyId: groupMeta?['company_id'] as String?,
      groupName: groupMeta?['name'] as String?,
      description: groupMeta?['decription'] as String?,
    );
  }
}
