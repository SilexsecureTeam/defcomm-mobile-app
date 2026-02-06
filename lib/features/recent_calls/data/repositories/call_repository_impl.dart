import 'package:defcomm/features/recent_calls/data/datasources/calls_local_data_source.dart';
import 'package:fpdart/fpdart.dart';
import '../../domain/entities/call_entity.dart';
import '../datasources/call_remote_datasource.dart';

abstract class CallsRepository {
  Future<Either<Exception, List<CallEntity>>> getRecentCalls();
}


class CallsRepositoryImpl implements CallsRepository {
  final CallsRemoteDataSource remote;
  final CallsLocalDataSource local; 

  CallsRepositoryImpl({
    required this.remote, 
    required this.local 
  });

  @override
  Future<Either<Exception, List<CallEntity>>> getRecentCalls() async {
    try {
      final models = await remote.fetchRecentCalls();
      
      try {
        await local.cacheCalls(models);
      } catch (e) {
        print("Cache calls failed: $e");
      }

      final entities = models.map((m) => m.toEntity()).toList(growable: false);
      
      return Right(entities);
    } catch (e) {
      return Left(Exception('Failed to fetch recent calls: $e'));
    }
  }
}
