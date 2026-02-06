import 'package:defcomm/features/chat_details/data/models/chat_messge_model.dart';

import '../../domain/entities/chat_page.dart';

class ChatPageModel extends ChatPage {
  const ChatPageModel({
    required super.messages,
    required super.currentPage,
    required super.lastPage,
  });

  factory ChatPageModel.fromJson(Map<String, dynamic> map) {
    final chatMeta = map['chat_meta'] as Map<String, dynamic>;
    final messagesData = map['data'] as List;

    return ChatPageModel(
      currentPage: chatMeta['current_page'] as int,
      lastPage: chatMeta['last_page'] as int,
      messages: messagesData
          .map((msgJson) => ChatMessageModel.fromJson(msgJson))
          .toList(),
    );
  }
}