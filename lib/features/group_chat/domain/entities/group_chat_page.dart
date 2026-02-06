import 'package:equatable/equatable.dart';
import 'group_chat_message.dart';

class GroupChatPage extends Equatable {
  final List<GroupChatMessage> messages;
  final bool hasMorePages;
  final int currentPage;

  const GroupChatPage({
    required this.messages,
    required this.hasMorePages,
    required this.currentPage,
  });

  @override
  List<Object?> get props => [messages, hasMorePages, currentPage];
}
