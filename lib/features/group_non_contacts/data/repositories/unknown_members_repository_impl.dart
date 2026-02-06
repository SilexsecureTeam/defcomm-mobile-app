import 'package:defcomm/features/group_non_contacts/domain/repoitories/unknown_members_repository.dart';
import 'package:defcomm/features/groups/data/models/group_member_model.dart';
import 'package:defcomm/features/messaging/data/models/story_models.dart';
import '../../domain/entities/unknown_group_member.dart';
import '../datasources/unknown_members_remote_data_source.dart';
import '../models/unknown_group_member_model.dart';

class UnknownMembersRepositoryImpl implements UnknownMembersRepository {
  final UnknownMembersRemoteDataSource remoteDataSource;

  UnknownMembersRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<UnknownGroupMember>> getUnknownMembers(String groupId) async {
    try {
      // 1. Fetch My Contacts
      // FIX: No need to map() here. It is ALREADY List<StoryModel>
      final List<StoryModel> myContacts = await remoteDataSource.fetchMyContacts();

      // 2. Fetch Group Members
      // FIX: No need to map() here. It is ALREADY List<GroupMemberModel>
      final List<GroupMemberModel> groupMembers = await remoteDataSource.fetchGroupMembers(groupId);

      // 3. THE LOGIC (remains the same)
      final Set<int> myContactIds = myContacts
          .where((c) => c.contactId != null)
          .map((c) => c.contactId!)
          .toSet();

      final List<UnknownGroupMember> unknownMembers = [];

      for (var member in groupMembers) {
        if (member.memberId != null && !myContactIds.contains(member.memberId)) {
          unknownMembers.add(UnknownGroupMemberModel.fromGroupMember(member));
        }
      }

      return unknownMembers;
    } catch (e) {
      throw Exception('Failed to calculate unknown members: $e');
    }
  }
}