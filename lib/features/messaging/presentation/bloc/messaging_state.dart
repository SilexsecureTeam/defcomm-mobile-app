// presentation/bloc/messaging_state.dart
import 'package:defcomm/features/groups/domain/entities/group_entity.dart';
import 'package:defcomm/features/messaging/domain/entities/message_group_entity.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/story.dart';
import '../../domain/entities/message_thread.dart';

class MessagingState extends Equatable {
  final List<Story> stories;
  final List<MessageThread> threads;
  final List<GroupEntity> groups;

  final bool storiesLoading;
  final bool threadsLoading;
  final bool groupsLoading;

  final String? storiesError;
  final String? threadsError;
  final String? groupError;

  const MessagingState({
    this.stories = const [],
    this.threads = const [],
    this.groups = const [],

    this.storiesLoading = true,
    this.threadsLoading = true,
    this.groupsLoading = true,

    this.storiesError,
    this.threadsError,
    this.groupError,
  });

  MessagingState copyWith({
    List<Story>? stories,
    List<MessageThread>? threads,
    List<GroupEntity>? groups,

    bool? storiesLoading,
    bool? threadsLoading,
    bool? groupsLoading,


    String? storiesError,
    String? threadsError,
    String? groupError,
  }) {
    return MessagingState(
      stories: stories ?? this.stories,
      threads: threads ?? this.threads,
      groups: groups ?? this.groups,

      storiesLoading: storiesLoading ?? this.storiesLoading,
      threadsLoading: threadsLoading ?? this.threadsLoading,
      groupsLoading: groupsLoading ?? this.groupsLoading,

      storiesError: storiesError,
      threadsError: threadsError,
      groupError: groupError
    );
  }

  @override
  List<Object?> get props => [
        stories,
        threads,
        groups,

        storiesLoading,
        threadsLoading,
        groupsLoading,

        storiesError,
        threadsError,
        groupError
      ];
}
