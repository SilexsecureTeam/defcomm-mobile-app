import 'package:defcomm/core/error/failures.dart';
import 'package:defcomm/features/groups/data/models/group_member_model.dart';
import 'package:fpdart/fpdart.dart';

import '../entities/group_entity.dart';

abstract class GroupRepository {
  Future<Either<Failure, List<GroupEntity>>> getJoinedGroups();
  Future<Either<Failure, List<GroupEntity>>> getPendingGroups();
  Future<Either<Failure, void>> acceptInvitation(String groupId);
  Future<Either<Failure, void>> declineInvitation(String groupId);
  Future<Either<Failure, List<GroupMemberModel>>> getGroupMembers(String groupId);
}