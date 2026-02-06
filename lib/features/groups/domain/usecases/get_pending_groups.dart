
import 'package:defcomm/core/error/failures.dart';
import 'package:fpdart/fpdart.dart';

import '../entities/group_entity.dart';
import '../repositories/group_repository.dart';

class GetPendingGroups {
  final GroupRepository repository;

  GetPendingGroups(this.repository);

  Future<Either<Failure, List<GroupEntity>>> call() async {
    return await repository.getPendingGroups();
  }
}