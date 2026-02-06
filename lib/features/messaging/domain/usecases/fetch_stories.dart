import 'package:defcomm/features/messaging/domain/repositories/messaging_repositories.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/story.dart';

class FetchStories implements UseCase<List<Story>, NoParams> {
  final MessagingRepository messagingRepository;
  FetchStories(this.messagingRepository);

  @override
  Future<Either<Failure, List<Story>>> call(NoParams params) async {
    return await messagingRepository.fetchStories();
  }
}