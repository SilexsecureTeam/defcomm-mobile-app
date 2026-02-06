import 'package:defcomm/core/error/failures.dart';
import 'package:defcomm/features/messaging/domain/entities/story.dart';
import 'package:defcomm/features/messaging/domain/repositories/messaging_repositories.dart';
import 'package:fpdart/fpdart.dart';

class GetCachedStories {
  final MessagingRepository repository;
  GetCachedStories(this.repository);

  Future<Either<Failure, List<Story>>> call() async {
    return await repository.getCachedStories();
  }
}