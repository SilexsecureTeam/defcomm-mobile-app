import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_unknown_members.dart';
import 'unknown_members_event.dart';
import 'unknown_members_state.dart';

class UnknownMembersBloc extends Bloc<UnknownMembersEvent, UnknownMembersState> {
  final GetUnknownMembers _getUnknownMembers;

  UnknownMembersBloc({
    required GetUnknownMembers getUnknownMembers,
  })  : _getUnknownMembers = getUnknownMembers,
        super(UnknownMembersInitial()) {
    
    on<FetchUnknownMembers>((event, emit) async {
      emit(UnknownMembersLoading());
      try {
        final result = await _getUnknownMembers(event.groupId);
        if (result.isEmpty) {
           // You could treat empty as "Loaded with empty list" or a specific state
           emit(const UnknownMembersLoaded([]));
        } else {
           emit(UnknownMembersLoaded(result));
        }
      } catch (e) {
        emit(UnknownMembersError(e.toString()));
      }
    });
  }
}