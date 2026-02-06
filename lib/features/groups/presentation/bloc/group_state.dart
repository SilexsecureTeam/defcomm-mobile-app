import 'package:defcomm/features/groups/domain/entities/group_entity.dart';
import 'package:equatable/equatable.dart';

abstract class GroupState extends Equatable {
  const GroupState();
  @override
  List<Object> get props => [];
}

class GroupInitial extends GroupState {}

class GroupLoading extends GroupState {}

class GroupLoaded extends GroupState {
  final List<GroupEntity> joinedGroups;
  final List<GroupEntity> pendingGroups;

  const GroupLoaded({required this.joinedGroups, required this.pendingGroups});

  @override
  List<Object> get props => [joinedGroups, pendingGroups];
}

class GroupActionSuccess extends GroupState {
  final String message;
  const GroupActionSuccess(this.message);
}

class GroupFailure extends GroupState {
  final String message;
  const GroupFailure(this.message);
}