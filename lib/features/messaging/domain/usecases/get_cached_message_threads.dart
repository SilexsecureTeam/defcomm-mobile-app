import 'package:defcomm/core/error/failures.dart';
import 'package:defcomm/features/messaging/domain/entities/message_thread.dart';
import 'package:defcomm/features/messaging/domain/repositories/messaging_repositories.dart';
import 'package:fpdart/fpdart.dart';

class GetCachedMessageThreads {
  final MessagingRepository repository;
  GetCachedMessageThreads(this.repository);

  Future<Either<Failure, List<MessageThread>>> call() async {
    return await repository.getCachedMessageThreads();
  }
}