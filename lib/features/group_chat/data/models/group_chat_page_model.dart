import '../../domain/entities/group_chat_page.dart';
import '../../domain/entities/group_chat_message.dart';
import 'group_chat_message_model.dart';

class GroupChatPageModel extends GroupChatPage {
  const GroupChatPageModel({
    required List<GroupChatMessage> messages,
    required bool hasMorePages,
    required int currentPage,
  }) : super(
          messages: messages,
          hasMorePages: hasMorePages,
          currentPage: currentPage,
        );

  factory GroupChatPageModel.fromJson(Map<String, dynamic> json) {
    final meta =
        (json['chat_meta'] as Map<String, dynamic>? ?? <String, dynamic>{});
    final data = (json['data'] as List<dynamic>? ?? const []);

    final messages = data
        .map((e) => GroupChatMessageModel.fromJson(
            e as Map<String, dynamic>))
        .toList();

    final current = meta['current_page'] is int
        ? meta['current_page'] as int
        : int.tryParse(meta['current_page']?.toString() ?? '1') ?? 1;
    final last = meta['last_page'] is int
        ? meta['last_page'] as int
        : int.tryParse(meta['last_page']?.toString() ?? '$current') ??
            current;

    return GroupChatPageModel(
      messages: messages,
      hasMorePages: current < last,
      currentPage: current,
    );
  }
}
