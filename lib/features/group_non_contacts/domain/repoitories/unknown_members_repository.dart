import '../entities/unknown_group_member.dart';

abstract class UnknownMembersRepository {
  // Returns a list of members in the group who are NOT in my contacts
  Future<List<UnknownGroupMember>> getUnknownMembers(String groupId);
}