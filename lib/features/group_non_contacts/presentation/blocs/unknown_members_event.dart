import 'package:equatable/equatable.dart';

abstract class UnknownMembersEvent extends Equatable {
  const UnknownMembersEvent();
  @override
  List<Object> get props => [];
}

class FetchUnknownMembers extends UnknownMembersEvent {
  final String groupId;
  const FetchUnknownMembers(this.groupId);
  @override
  List<Object> get props => [groupId];
}