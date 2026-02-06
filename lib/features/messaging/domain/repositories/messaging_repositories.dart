import 'package:defcomm/features/groups/domain/entities/group_entity.dart';
import 'package:defcomm/features/messaging/domain/entities/message_thread.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/story.dart';

abstract interface class MessagingRepository {
  Future<Either<Failure, List<Story>>> fetchStories();
   Future<Either<Failure, List<Story>>> getCachedStories(); 

   Future<Either<Failure, List<MessageThread>>> fetchMessageThreads();
   Future<Either<Failure, List<MessageThread>>> getCachedMessageThreads();

   Future<Either<Failure, List<GroupEntity>>> getJoinedGroups();
   Future<Either<Failure, List<GroupEntity>>> getCachedGroups();
}