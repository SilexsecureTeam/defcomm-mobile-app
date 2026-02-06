import 'package:fpdart/fpdart.dart';
import '../entities/call_entity.dart';
import '../../data/repositories/call_repository_impl.dart';

class GetRecentCalls {
  final CallsRepository repository;

  GetRecentCalls(this.repository);

  Future<Either<Exception, List<CallEntity>>> call() {
    return repository.getRecentCalls();
  }
}
