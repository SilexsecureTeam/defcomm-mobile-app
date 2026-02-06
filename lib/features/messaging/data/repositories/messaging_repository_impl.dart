import 'package:defcomm/core/error/exception.dart';
import 'package:defcomm/features/groups/domain/entities/group_entity.dart';
import 'package:defcomm/features/messaging/data/datasources/messaging_local_datasource.dart';
import 'package:defcomm/features/messaging/data/datasources/messaging_remote_datasource.dart';
import 'package:defcomm/features/messaging/data/models/story_models.dart';
import 'package:defcomm/features/messaging/domain/entities/message_group_entity.dart';
import 'package:defcomm/features/messaging/domain/entities/message_thread.dart';
import 'package:defcomm/features/messaging/domain/repositories/messaging_repositories.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/story.dart';

class MessagingRepositoryImpl implements MessagingRepository {
  final MessagingRemoteDataSource remoteDataSource;
  final MessagingLocalDataSource localDataSource;

  MessagingRepositoryImpl(
    this.remoteDataSource,
    this.localDataSource, 
  );

  @override
  Future<Either<Failure, List<Story>>> fetchStories() async {
    try {
      final stories = await remoteDataSource.fetchStories();
      localDataSource.cacheStories(stories);
      return Right(stories);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Story>>> getCachedStories() async {
    try {
      final local = localDataSource.getLastStories();
      return Right(local);
    } catch (e) {
      return Left(CacheFailure("No cache"));
    }
  }

  @override
  Future<Either<Failure, List<MessageThread>>> fetchMessageThreads() async {
    try {
      final threads = await remoteDataSource.fetchMessageThreads();
      localDataSource.cacheThreads(threads);
      return Right(threads);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<MessageThread>>> getCachedMessageThreads() async {
    try {
      final local = localDataSource.getLastThreads();
      return Right(local);
    } catch (e) {
      return Left(CacheFailure("No cache"));
    }
  }

  @override
  Future<Either<Failure, List<GroupEntity>>> getJoinedGroups() async {
    try {
      final remoteGroups = await remoteDataSource.getJoinedGroups();
      localDataSource.cacheGroups(remoteGroups);
      final groupEntities = remoteGroups.map((m) => m.toEntity()).toList();
      return Right(groupEntities);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<GroupEntity>>> getCachedGroups() async {
    try {
      final localModels = localDataSource.getLastGroups();
      final groupEntities = localModels.map((m) => m.toEntity()).toList();
      return Right(groupEntities);
    } catch (e) {
      return Left(CacheFailure("No cache"));
    }
  }
}