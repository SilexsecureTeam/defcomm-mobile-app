import 'package:equatable/equatable.dart';

abstract class GroupEvent extends Equatable {
  const GroupEvent();
  @override
  List<Object> get props => [];
}

class FetchAllGroups extends GroupEvent {}

class AcceptGroupInvitation extends GroupEvent {
  final String groupId;
  const AcceptGroupInvitation(this.groupId);
  @override
  List<Object> get props => [groupId];
}

class DeclineGroupInvitation extends GroupEvent {
  final String groupId;
  const DeclineGroupInvitation(this.groupId);
  @override
  List<Object> get props => [groupId];
}
