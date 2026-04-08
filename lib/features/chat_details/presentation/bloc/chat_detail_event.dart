import 'package:defcomm/features/chat_details/domain/entities/chat_message.dart';
import 'package:equatable/equatable.dart';

abstract class ChatDetailEvent extends Equatable {
  const ChatDetailEvent();
}

// Event to fetch messages, can be for the first page or subsequent pages
class MessagesFetched extends ChatDetailEvent {
  final String chatUserId;
  const MessagesFetched(this.chatUserId);

  @override
  List<Object> get props => [chatUserId];
}

class ChatReset extends ChatDetailEvent {
  @override
  List<Object> get props => [];
}

class MessageSent extends ChatDetailEvent {
  final String message;
  final String chatUserId;
  // You might need other parameters like chatId

  const MessageSent({required this.message, required this.chatUserId});

  @override
  List<Object> get props => [message, chatUserId];
}

// Incoming message payload could be a Map or a strongly typed Message model
class IncomingMessageEvent extends ChatDetailEvent {
  final ChatMessage message;

  const IncomingMessageEvent(this.message);

  @override
  List<Object?> get props => [message];
}

class UpdateTypingEvent extends ChatDetailEvent {
  final String userId;
  final bool isTyping;
  const UpdateTypingEvent({required this.userId, required this.isTyping});
  @override
  List<Object?> get props => [userId, isTyping];
}

class LoadCachedMessages extends ChatDetailEvent {
  final List<ChatMessage> messages;
  const LoadCachedMessages(this.messages);
  @override
  List<Object> get props => [messages];
}

class RefreshChatEvent extends ChatDetailEvent {
  final String chatUserId;
  const RefreshChatEvent(this.chatUserId);
  @override
  List<Object> get props => [chatUserId];
}
