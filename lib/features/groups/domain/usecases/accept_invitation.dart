
import 'package:defcomm/core/error/failures.dart';
import 'package:fpdart/fpdart.dart';

import '../repositories/group_repository.dart';

class AcceptInvitation {
  final GroupRepository repository;

  AcceptInvitation(this.repository);

  Future<Either<Failure, void>> call(String groupId) async {
    return await repository.acceptInvitation(groupId);
  }
}