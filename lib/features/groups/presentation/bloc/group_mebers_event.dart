import 'package:equatable/equatable.dart';

abstract class GroupMembersEvent extends Equatable {
  const GroupMembersEvent();

  @override
  List<Object?> get props => [];
}

class FetchGroupMembers extends GroupMembersEvent {
  final String groupId;
  const FetchGroupMembers(this.groupId);

  @override
  List<Object?> get props => [groupId];
}
