import 'package:defcomm/core/error/failures.dart';
import 'package:defcomm/features/groups/domain/entities/group_entity.dart';
import 'package:defcomm/features/messaging/domain/repositories/messaging_repositories.dart';
import 'package:fpdart/fpdart.dart';

class GetCachedGroups {
  final MessagingRepository repository;
  GetCachedGroups(this.repository);

  Future<Either<Failure, List<GroupEntity>>> call() async {
    return await repository.getCachedGroups();
  }
}