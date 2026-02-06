import 'package:defcomm/core/error/exception.dart';
import 'package:defcomm/features/group_chat/data/datasources/group_chat_local_data_source.dart';
import 'package:defcomm/features/group_chat/data/models/group_chat_message_model.dart';
import 'package:defcomm/features/group_chat/data/models/group_chat_page_model.dart';
import 'package:defcomm/features/group_chat/domain/entities/group_chat_message.dart';
import 'package:defcomm/features/group_chat/domain/usecases/send_group_message.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/group_chat_page.dart';
import '../../domain/repositories/group_chat_repository.dart';
import '../datasources/group_chat_remote_data_source.dart';

class GroupChatRepositoryImpl implements GroupChatRepository {
  final GroupChatRemoteDataSource remoteDataSource;
   final GroupChatLocalDataSource localDataSource;

  GroupChatRepositoryImpl(this.remoteDataSource, this.localDataSource);

  @override
  Future<Either<Failure, GroupChatPage>> fetchGroupMessages({
    required String groupUserIdEn,
    required int page,
  }) async {
    try {
      final pageModel = await remoteDataSource.getGroupMessages(
        groupUserIdEn: groupUserIdEn,
        page: page,
      );

      if (page == 1) {
        await localDataSource.cacheMessages(
          groupUserIdEn, 
          pageModel.messages.cast<GroupChatMessageModel>()
        );
      }


      return Right(pageModel);
    } on ServerException catch (e) {
      if (page == 1) {
        try {
          final local = await localDataSource.getLocalMessages(groupUserIdEn);
          if (local.isNotEmpty) {
             return Right(GroupChatPageModel(
               messages: local, 
               hasMorePages: false,
               currentPage: 1
             ));
          }
        } catch (_) {}
      }


      return Left(ServerFailure(e.message));
    } catch (_) {
      return Left(ServerFailure('Unexpected error occurred'));
    }
  }


   @override
  Future<Either<Failure, GroupChatMessage>> sendGroupMessage(
    SendGroupMessageParams params,
  ) async {
    try {
      final result = await remoteDataSource.sendGroupMessage(params);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return Left(ServerFailure('Unexpected error sending group message'));
    }
  }
}
