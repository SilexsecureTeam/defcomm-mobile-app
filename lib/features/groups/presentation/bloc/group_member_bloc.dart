// features/group/presentation/bloc/group_members_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:defcomm/features/groups/domain/usecases/get_group_members.dart';
import 'package:defcomm/features/groups/presentation/bloc/group_embers_state.dart';
import 'package:defcomm/features/groups/presentation/bloc/group_mebers_event.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';

class GroupMembersBloc extends Bloc<GroupMembersEvent, GroupMembersState> {
  final GetGroupMembers getGroupMembers;

  GroupMembersBloc({required this.getGroupMembers}) : super(const GroupMembersInitial()) {
    on<FetchGroupMembers>(_onFetchGroupMembers);
  }

  Future<void> _onFetchGroupMembers(FetchGroupMembers event, Emitter<GroupMembersState> emit) async {
    emit(const GroupMembersLoading());

    final Either<Failure, List> result = await getGroupMembers(event.groupId);

    result.match(
      (failure) => emit(GroupMembersFailure(failure.message)),
      (members) => emit(GroupMembersLoaded(List.from(members))),
    );
  }
}
