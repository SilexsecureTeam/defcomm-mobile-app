import 'package:defcomm/features/groups/data/models/group_member_model.dart';

class GroupMembersResponse {
  final String status;
  final String message;
  final Map<String, dynamic>? groupMeta;
  final List<GroupMemberModel> members;

  GroupMembersResponse({
    required this.status,
    required this.message,
    required this.groupMeta,
    required this.members,
  });

  factory GroupMembersResponse.fromJson(Map<String, dynamic> map) {
    final rawMembers = (map['data'] as List?) ?? [];
    final groupMeta = map['group_meta'] as Map<String, dynamic>?;

    return GroupMembersResponse(
      status: map['status']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      groupMeta: groupMeta,
      members: rawMembers
          .map(
            (e) => GroupMemberModel.fromJson(
              e as Map<String, dynamic>,
              groupMeta,
            ),
          )
          .toList(),
    );
  }
}
