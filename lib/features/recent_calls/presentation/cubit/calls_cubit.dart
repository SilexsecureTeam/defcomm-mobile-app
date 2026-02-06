import 'package:bloc/bloc.dart';
import 'package:defcomm/features/recent_calls/domain/usecases/get_local_calls.dart';
import 'package:fpdart/fpdart.dart' as f;
import 'calls_state.dart';
import '../../domain/usecases/get_recent_calls.dart';
import '../../domain/entities/call_entity.dart';

class CallsCubit extends Cubit<CallsState> {
  final GetRecentCalls getRecentCalls;
  final GetLocalCalls getLocalCalls; 

  CallsCubit({
    required this.getRecentCalls,
    required this.getLocalCalls,
  }) : super(CallsState.initial());

  Future<void> load() async {
 
    if (state.calls.isEmpty) {
      final localData = await getLocalCalls.call();
      if (localData.isNotEmpty) {
        emit(state.copyWith(
          isLoading: false, 
          calls: localData.reversed.toList(),
          error: null
        ));
      } else {
        emit(state.copyWith(isLoading: true, error: null));
      }
    }

    final res = await getRecentCalls.call();
    
    res.match(
      (l) {
        if (state.calls.isNotEmpty) {
        } else {
           emit(state.copyWith(isLoading: false, error: l.toString()));
        }
      },
      (r) {
        emit(state.copyWith(
          isLoading: false, 
          calls: r.reversed.toList(), 
          error: null
        ));
      },
    );
  }
}