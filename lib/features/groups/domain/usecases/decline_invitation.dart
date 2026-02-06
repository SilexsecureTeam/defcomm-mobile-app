
import 'package:defcomm/core/error/failures.dart';
import 'package:fpdart/fpdart.dart';

import '../repositories/group_repository.dart';

class DeclineInvitation {
  final GroupRepository repository;

  DeclineInvitation(this.repository);

  Future<Either<Failure, void>> call(String groupId) async {
    return await repository.declineInvitation(groupId);
  }
}