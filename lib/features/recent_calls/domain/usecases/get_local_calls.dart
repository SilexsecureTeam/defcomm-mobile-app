// features/recent_calls/domain/usecases/get_local_calls.dart

import '../entities/call_entity.dart';
import '../../data/datasources/calls_local_data_source.dart';

class GetLocalCalls {
  final CallsLocalDataSource localDataSource;

  GetLocalCalls(this.localDataSource);

  Future<List<CallEntity>> call() async {
    final models = await localDataSource.getLocalCalls();
    
    return models.map((m) => m.toEntity()).toList(); 
  }
}