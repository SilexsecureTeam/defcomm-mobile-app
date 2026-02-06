import 'package:defcomm/features/chat_details/data/models/chat_user_model.dart';

class MessageThread {
  final ChatUser user;
  // final String imageUrl;
  // final String name;
  final String time;
  final bool hasUnread;

  MessageThread({
    required this.user,
    // required this.imageUrl,
    // required this.name,
    required this.time,
    this.hasUnread = false,
  });
}