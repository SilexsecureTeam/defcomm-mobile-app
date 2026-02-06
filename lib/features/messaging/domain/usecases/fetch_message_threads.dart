import 'package:defcomm/features/messaging/domain/repositories/messaging_repositories.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/message_thread.dart';

class FetchMessageThreads implements UseCase<List<MessageThread>, NoParams> {
  final MessagingRepository messagingRepository;
  FetchMessageThreads(this.messagingRepository);

  @override
  Future<Either<Failure, List<MessageThread>>> call(NoParams params) async {
    return await messagingRepository.fetchMessageThreads();
  }
}