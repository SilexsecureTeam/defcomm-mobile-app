import 'package:defcomm/core/error/failures.dart';
import 'package:defcomm/features/groups/domain/entities/group_entity.dart';
import 'package:defcomm/features/groups/domain/repositories/group_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetJoinedGroups {
  final GroupRepository repository;
  GetJoinedGroups(this.repository);

  Future<Either<Failure, List<GroupEntity>>> call() async {
    return await repository.getJoinedGroups();
  }
}