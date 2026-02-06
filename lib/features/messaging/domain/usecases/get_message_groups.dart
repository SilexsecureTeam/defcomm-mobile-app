import 'package:defcomm/core/error/failures.dart';
import 'package:defcomm/features/groups/domain/entities/group_entity.dart';
import 'package:defcomm/features/messaging/domain/entities/message_group_entity.dart';
import 'package:defcomm/features/messaging/domain/repositories/messaging_repositories.dart';
import 'package:fpdart/fpdart.dart';

class GetMessageJoinedGroups {
  final MessagingRepository repository;
  GetMessageJoinedGroups(this.repository);

  Future<Either<Failure, List<GroupEntity>>> call() async {
    return await repository.getJoinedGroups();
  }
}