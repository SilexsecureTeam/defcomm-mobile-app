import 'package:equatable/equatable.dart';

import '../../domain/entities/group_chat_message.dart';

abstract class GroupChatState extends Equatable {
  const GroupChatState();
}

class GroupChatInitial extends GroupChatState {
  @override
  List<Object?> get props => [];
}

class GroupChatLoading extends GroupChatState {
  @override
  List<Object?> get props => [];
}


class GroupChatLoaded extends GroupChatState {
  final List<GroupChatMessage> messages;
  final bool hasReachedMax;
  final GroupChatMessage? replyTo; 
  final List<String> taggedUserIds;


   final Set<String> endedCallIds; 

  const GroupChatLoaded({
    required this.messages,
    required this.hasReachedMax,
    this.replyTo,
    this.taggedUserIds = const [],
    this.endedCallIds = const {}
  });

  GroupChatLoaded copyWith({
    List<GroupChatMessage>? messages,
    bool? hasReachedMax,
    GroupChatMessage? replyTo, 
    List<String>? taggedUserIds,
    Set<String>? endedCallIds
  }) {
    return GroupChatLoaded(
      messages: messages ?? this.messages,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      replyTo: replyTo,
      taggedUserIds: taggedUserIds ?? this.taggedUserIds,
      endedCallIds: endedCallIds ?? this.endedCallIds,
    );
  }

  @override
  List<Object?> get props => [messages, hasReachedMax, replyTo, taggedUserIds, endedCallIds];
}

class GroupChatFailure extends GroupChatState {
  final String message;
  const GroupChatFailure(this.message);

  @override
  List<Object?> get props => [message];
}
