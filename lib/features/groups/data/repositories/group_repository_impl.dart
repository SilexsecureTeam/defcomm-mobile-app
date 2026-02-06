
import 'package:defcomm/core/error/failures.dart';
import 'package:defcomm/features/groups/data/datsources/group_remote_data_source.dart';
import 'package:defcomm/features/groups/data/models/group_member_model.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exception.dart'; // You need a ServerException class
import '../../domain/entities/group_entity.dart';
import '../../domain/repositories/group_repository.dart';

class GroupRepositoryImpl implements GroupRepository {
  final GroupRemoteDataSource remoteDataSource;

  GroupRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<GroupEntity>>> getJoinedGroups() async {
    try {
      final remoteGroups = await remoteDataSource.getJoinedGroups();
      final groupEntities = remoteGroups.map((model) => model.toEntity()).toList();
      return Right(groupEntities);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<GroupEntity>>> getPendingGroups() async {
    try {
      final remoteGroups = await remoteDataSource.getPendingGroups();
      final groupEntities = remoteGroups.map((model) => model.toEntity()).toList();
      return Right(groupEntities);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
  
  @override
  Future<Either<Failure, void>> acceptInvitation(String groupId) async {
    try {
      await remoteDataSource.acceptInvitation(groupId);
      return const Right(null); 
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> declineInvitation(String groupId) async {
    try {
      await remoteDataSource.declineInvitation(groupId);
      return const Right(null);
    } on ServerException catch(e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<GroupMemberModel>>> getGroupMembers(String groupId) async {
    try {
      final response = await remoteDataSource.fetchGroupMembers(groupId);
      
      return Right(response.members);
    } on Failure catch (f) {
      return Left(f);
    } catch (e, st) {
      return Left(ServerFailure(e.toString()));
    }
  }
}