import 'package:equatable/equatable.dart';
import 'chat_message.dart';

class ChatPage extends Equatable {
  final List<ChatMessage> messages;
  final int currentPage;
  final int lastPage;

  const ChatPage({
    required this.messages,
    required this.currentPage,
    required this.lastPage,
  });

  // Helper to know if there are more pages to load
  bool get hasMorePages => currentPage < lastPage;

  @override
  List<Object?> get props => [messages, currentPage, lastPage];
}