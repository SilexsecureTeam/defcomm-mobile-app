// lib/features/group_chat/presentation/bloc/group_chat_event.dart
import 'package:defcomm/features/group_chat/domain/entities/group_chat_message.dart';
import 'package:equatable/equatable.dart';

abstract class GroupChatEvent extends Equatable {
  const GroupChatEvent();
}

class GroupMessagesFetched extends GroupChatEvent {
  final String groupUserIdEn;
  const GroupMessagesFetched(this.groupUserIdEn);

  @override
  List<Object?> get props => [groupUserIdEn];
}

class GroupMessageSent extends GroupChatEvent {
  final String message;
  final String groupUserIdEn;
  final List<String> tagUserIds;

  const GroupMessageSent({
    required this.message,
    required this.groupUserIdEn,
    this.tagUserIds = const [],
  });

  @override
  List<Object?> get props => [message, groupUserIdEn, tagUserIds];
}

class GroupReplySelected extends GroupChatEvent {
  final GroupChatMessage message;
  const GroupReplySelected(this.message);

  @override
  List<Object?> get props => [message];
}

class GroupReplyCleared extends GroupChatEvent {
  @override
  List<Object?> get props => [];
}

class TagUserSelected extends GroupChatEvent {
  final String userId;
  const TagUserSelected(this.userId);

  @override
  List<Object?> get props => [userId];

}

class GroupIncomingMessageReceived extends GroupChatEvent {
  final Map<String, dynamic> payload;

  const GroupIncomingMessageReceived(this.payload);

  @override
  List<Object?> get props => [payload];
}
