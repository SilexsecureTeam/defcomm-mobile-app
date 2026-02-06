import 'package:defcomm/features/groups/data/models/group_member_model.dart';

import '../../domain/entities/unknown_group_member.dart';

// We can extend the entity to keep things clean
class UnknownGroupMemberModel extends UnknownGroupMember {
  const UnknownGroupMemberModel({
    required super.id,
    required super.memberId,
    required super.name,
    super.role,
    super.imageUrl,
  });

  // Factory to convert from your EXISTING GroupMemberModel to this specific Entity
  factory UnknownGroupMemberModel.fromGroupMember(GroupMemberModel member) {
    return UnknownGroupMemberModel(
      id: member.id,
      memberId: member.memberId,
      name: member.memberName ?? 'Unknown',
      role: 'member', // Default or logic to check admin
      imageUrl: '', // Default image logic
    );
  }
}