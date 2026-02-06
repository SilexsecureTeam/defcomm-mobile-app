import 'package:equatable/equatable.dart';
import '../../data/models/group_member_model.dart';

abstract class GroupMembersState extends Equatable {
  const GroupMembersState();

  @override
  List<Object?> get props => [];
}

class GroupMembersInitial extends GroupMembersState {
  const GroupMembersInitial();
}

class GroupMembersLoading extends GroupMembersState {
  const GroupMembersLoading();
}

class GroupMembersLoaded extends GroupMembersState {
  final List<GroupMemberModel> members;
  const GroupMembersLoaded(this.members);

  @override
  List<Object?> get props => [members];
}

class GroupMembersFailure extends GroupMembersState {
  final String message;
  const GroupMembersFailure(this.message);

  @override
  List<Object?> get props => [message];
}
