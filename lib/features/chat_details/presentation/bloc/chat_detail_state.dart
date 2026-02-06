part of 'chat_detail_bloc.dart';

abstract class ChatDetailState extends Equatable {
  const ChatDetailState();
}

class ChatDetailInitial extends ChatDetailState {
  @override
  List<Object> get props => [];
}

class ChatDetailLoading extends ChatDetailState {
  @override
  List<Object> get props => [];
}

class ChatDetailLoaded extends ChatDetailState {
  final List<ChatMessage> messages;
  final bool hasReachedMax;
  final bool isTyping;

  const ChatDetailLoaded({
    required this.messages,
    required this.hasReachedMax,
    this.isTyping = false
  });

  ChatDetailLoaded copyWith({
    List<ChatMessage>? messages,
    bool? hasReachedMax,
    bool? isTyping,
  }) {
    return ChatDetailLoaded(
      messages: messages ?? this.messages,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isTyping: isTyping ?? this.isTyping,
    );
  }

  @override
  List<Object> get props => [messages, hasReachedMax, isTyping];
}

class ChatDetailFailure extends ChatDetailState {
  final String message;
  const ChatDetailFailure(this.message);

  @override
  List<Object> get props => [message];
}