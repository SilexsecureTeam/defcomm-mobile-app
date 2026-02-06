import 'package:defcomm/features/messaging/domain/entities/message_thread.dart';
import 'package:equatable/equatable.dart';

abstract class MessagingEvent extends Equatable {
  const MessagingEvent();
}

class FetchStoriesEvent extends MessagingEvent {
  @override
  List<Object> get props => [];
}

class FetchMessageThreadsEvent extends MessagingEvent {
  final String? markedReadThreadId;

  const FetchMessageThreadsEvent({this.markedReadThreadId});
  @override
  List<Object> get props => [];
}

class NewThreadCreatedEvent extends MessagingEvent {
  final MessageThread thread;
  final bool shouldIncrementCount;
  final bool shouldResetCount;
  
  final bool useProvidedUnreadCount; 

  const NewThreadCreatedEvent(
    this.thread, {
    this.shouldIncrementCount = true,
    this.shouldResetCount = false,
    this.useProvidedUnreadCount = false, 
  });

  @override
  List<Object?> get props => [
    thread, 
    shouldIncrementCount, 
    shouldResetCount, 
    useProvidedUnreadCount
  ];
}


class FetchGroupEvent extends MessagingEvent {
  @override
  List<Object> get props => [];
}

class ThreadRead extends MessagingEvent {
  final String threadId;
  const ThreadRead(this.threadId);

  @override
  List<Object?> get props => [threadId];
}

class IncomingGroupMessageEvent extends MessagingEvent {
  final String groupId;
  const IncomingGroupMessageEvent({required this.groupId});

  @override
  List<Object> get props => [groupId];
}

class GroupChatOpenedEvent extends MessagingEvent {
  final String groupId;
  const GroupChatOpenedEvent({required this.groupId});

  @override
  List<Object> get props => [groupId];
}



class UserTypingEvent extends MessagingEvent {
  final String userId; 
  final bool isTyping;

  const UserTypingEvent(this.userId, this.isTyping);

  @override
  List<Object> get props => [userId, isTyping];
}
