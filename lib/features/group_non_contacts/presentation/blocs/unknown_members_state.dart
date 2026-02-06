import 'package:equatable/equatable.dart';
import '../../domain/entities/unknown_group_member.dart';

abstract class UnknownMembersState extends Equatable {
  const UnknownMembersState();
  @override
  List<Object> get props => [];
}

class UnknownMembersInitial extends UnknownMembersState {}

class UnknownMembersLoading extends UnknownMembersState {}

class UnknownMembersLoaded extends UnknownMembersState {
  final List<UnknownGroupMember> members;
  const UnknownMembersLoaded(this.members);
  @override
  List<Object> get props => [members];
}

class UnknownMembersError extends UnknownMembersState {
  final String message;
  const UnknownMembersError(this.message);
  @override
  List<Object> get props => [message];
}