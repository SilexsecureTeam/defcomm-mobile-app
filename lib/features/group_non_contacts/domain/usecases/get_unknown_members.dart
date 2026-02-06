import 'package:defcomm/features/group_non_contacts/domain/repoitories/unknown_members_repository.dart';

import '../entities/unknown_group_member.dart';

class GetUnknownMembers {
  final UnknownMembersRepository repository;

  GetUnknownMembers(this.repository);

  Future<List<UnknownGroupMember>> call(String groupId) async {
    return await repository.getUnknownMembers(groupId);
  }
}