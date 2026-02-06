// features/group/domain/usecases/get_group_members.dart
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../repositories/group_repository.dart';
import '../../data/models/group_member_model.dart';

class GetGroupMembers {
  final GroupRepository repository;

  GetGroupMembers(this.repository);

  Future<Either<Failure, List<GroupMemberModel>>> call(String groupId) {
    return repository.getGroupMembers(groupId);
  }
}
