// presentation/bloc/messaging_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:defcomm/features/groups/domain/entities/group_entity.dart';
import 'package:defcomm/features/messaging/domain/entities/message_group_entity.dart';
import 'package:defcomm/features/messaging/domain/entities/message_thread.dart';
import 'package:defcomm/features/messaging/domain/entities/story.dart';
import 'package:defcomm/features/messaging/domain/usecases/fetch_message_threads.dart';
import 'package:defcomm/features/messaging/domain/usecases/fetch_stories.dart';
import 'package:defcomm/features/messaging/domain/usecases/get_cached_groups.dart';
import 'package:defcomm/features/messaging/domain/usecases/get_cached_message_threads.dart';
import 'package:defcomm/features/messaging/domain/usecases/get_cached_stories.dart';
import 'package:defcomm/features/messaging/domain/usecases/get_message_groups.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/error/failures.dart';
import 'messaging_event.dart';
import 'messaging_state.dart';
import 'package:defcomm/features/calling/call_control_constants.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class MessagingBloc extends Bloc<MessagingEvent, MessagingState> {
  final FetchStories _fetchStories;
  final FetchMessageThreads _fetchMessageThreads;
  final GetMessageJoinedGroups _getJoinedGroups;

  final GetCachedStories _getCachedStories;
  final GetCachedMessageThreads _getCachedThreads;
  final GetCachedGroups _getCachedGroups;

  // Tracks thread IDs the user has explicitly opened (read).
  // Persisted to GetStorage so badge stays gone after an app restart.
  static const _kReadIdsKey = 'messaging_read_thread_ids';
  final Set<String> _localReadThreadIds = {};
  final _box = GetStorage();

  // Set to true by _onNewThreadCreated when a real Pusher message reorders
  // the list. Checked by _onFetchThreads so it merges rather than replaces.
  bool _pusherReorderedSinceLastFetch = false;

  static bool _isCallControlMsg(String? msg) {
    if (msg == null || msg.isEmpty) return false;
    return msg.startsWith(kCallControlInvitePrefix) ||
        msg == kCallControlRejected ||
        msg == kCallControlEnded ||
        msg == kCallControlAccepted ||
        msg == 'voice_call' ||
        msg == 'call_accepted';
  }

  void _persistReadIds() {
    _box.write(_kReadIdsKey, _localReadThreadIds.toList());
  }

  void _loadReadIds() {
    final raw = _box.read(_kReadIdsKey);
    if (raw is List) {
      _localReadThreadIds.addAll(raw.map((e) => e.toString()));
    }
  }

  MessagingBloc({
    required FetchStories fetchStories,
    required FetchMessageThreads fetchMessageThreads,
    required GetMessageJoinedGroups getJoinedGroups,

    required GetCachedStories getCachedStories,
    required GetCachedMessageThreads getCachedThreads,
    required GetCachedGroups getCachedGroups,


    List<Story>? initialStories,
    List<MessageThread>? initialThreads,
    List<GroupEntity>? initialGroups,


  }) : _fetchStories = fetchStories,
       _fetchMessageThreads = fetchMessageThreads,
       _getJoinedGroups = getJoinedGroups,

       _getCachedStories = getCachedStories,
       _getCachedThreads = getCachedThreads,
       _getCachedGroups = getCachedGroups,

       super(MessagingState(
         stories: initialStories ?? [],
         threads: initialThreads ?? [],
         groups: initialGroups ?? [],
         
         storiesLoading: true, 
         threadsLoading: true,
         groupsLoading: true,
       )) {
    _loadReadIds();
    on<FetchStoriesEvent>(_onFetchStories);
    on<FetchMessageThreadsEvent>(_onFetchThreads);
    on<NewThreadCreatedEvent>(_onNewThreadCreated);
    on<FetchGroupEvent>(_onFetchGroupEvent);
    on<ThreadRead>(_onThreadRead);

    on<IncomingGroupMessageEvent>(_onIncomingGroupMessage);
    on<GroupChatOpenedEvent>(_onGroupChatOpened);
    on<UserTypingEvent>(_onUserTyping);
  }

  Future<void> _onFetchStories(
    FetchStoriesEvent event,
    Emitter<MessagingState> emit,
  ) async {
    emit(state.copyWith(storiesLoading: true, storiesError: null));

    final cachedResult = await _getCachedStories();
    cachedResult.fold(
      (failure) {},
      (stories) {
        if (stories.isNotEmpty) {
          emit(
            state.copyWith(
              stories: stories,
              storiesLoading: true, 
            ),
          );
        }
      },
    );

    final res = await _fetchStories(NoParams());
    res.fold(
      (failure) {
        if (state.stories.isEmpty) {
          emit(
            state.copyWith(
              storiesLoading: false,
              storiesError: failure.message,
            ),
          );
        } else {
          emit(state.copyWith(storiesLoading: false));
        }
        // emit(
        //   state.copyWith(storiesLoading: false, storiesError: failure.message),
        // );
      },
      (stories) {
        final storyList = List<Story>.from(stories);
        emit(
          state.copyWith(
            stories: storyList,
            storiesLoading: false,
            storiesError: null,
          ),
        );
      },
    );
  }

  Future<void> _onFetchThreads(
    FetchMessageThreadsEvent event,
    Emitter<MessagingState> emit,
  ) async {
    emit(state.copyWith(threadsLoading: true, threadsError: null));

    final cachedResult = await _getCachedThreads();
    cachedResult.fold((failure) {}, (threads) {
      // Only show cached threads as placeholder if the live state has none.
      // If live threads are already present (set by NewThreadCreatedEvent),
      // emitting the stale cache order causes the visible flicker/reorder.
      if (threads.isNotEmpty && state.threads.isEmpty) {
        final threadList = List<MessageThread>.from(threads);
        emit(state.copyWith(threads: threadList, threadsLoading: true));
      }
    });

    final res = await _fetchMessageThreads(NoParams());
    res.fold(
      (failure) {
        if (state.threads.isEmpty) {
          emit(
            state.copyWith(
              threadsLoading: false,
              threadsError: failure.message,
            ),
          );
        } else {
          emit(state.copyWith(threadsLoading: false));
        }
      },
      (threads) {
        var threadList = List<MessageThread>.from(threads);
        if (event.markedReadThreadId != null) {
          threadList = threadList.map((t) {
            if (t.id == event.markedReadThreadId.toString()) {
              return t.copyWith(unRead: 0);
            }
            return t;
          }).toList();
        }
        // Zero unread for threads whose last message is a call control signal.
        // The server counts call invite/reject/ended messages as unread — they
        // are not real chat messages and should never show a badge.
        threadList = threadList.map((t) {
          if (_isCallControlMsg(t.lastMessage)) {
            return t.copyWith(unRead: 0);
          }
          return t;
        }).toList();

        // Preserve locally-read threads: if the user already opened this
        // thread, don't let a stale server count re-show the unread badge.
        if (_localReadThreadIds.isNotEmpty) {
          threadList = threadList.map((t) {
            if (_localReadThreadIds.contains(t.id.toString())) {
              return t.copyWith(unRead: 0);
            }
            return t;
          }).toList();
        }
        // If a Pusher event reordered threads while this fetch was in-flight,
        // merge server content into the current in-memory order instead of
        // replacing it — avoids the "thread jumps to top then snaps back" bug.
        if (_pusherReorderedSinceLastFetch && state.threads.isNotEmpty) {
          _pusherReorderedSinceLastFetch = false;
          final serverById = {for (final t in threadList) t.id: t};
          final existingIds = state.threads.map((t) => t.id).toSet();
          // New threads from server not yet in memory → prepend them
          final newFromServer =
              threadList.where((t) => !existingIds.contains(t.id)).toList();
          // Update content of existing threads, preserving in-memory order
          threadList = [
            ...newFromServer,
            ...state.threads.map((t) => serverById[t.id] ?? t),
          ];
        } else {
          _pusherReorderedSinceLastFetch = false;
        }

        // API already returns threads ordered by most-recent message.
        // Do NOT sort by unRead count — that scrambles recency order.
        emit(
          state.copyWith(
            threads: threadList,
            threadsLoading: false,
            threadsError: null,
          ),
        );
      },
    );
  }

  Future<void> _onNewThreadCreated(
    NewThreadCreatedEvent event,
    Emitter<MessagingState> emit,
  ) async {
    final incomingThread = event.thread;

    final existingIndex = state.threads.indexWhere((t) {
      if (t.id.toString() == incomingThread.id.toString()) return true;
      if (t.chatId != null && incomingThread.chatId != null) {
        if (t.chatId.toString() == incomingThread.chatId.toString()) return true;
      }
      if (t.chatUserToId != null && incomingThread.chatUserToId != null) {
        if (t.chatUserToId.toString() == incomingThread.chatUserToId.toString()) return true;
      }
      return false;
    });

    final updatedList = List<MessageThread>.from(state.threads);

    if (existingIndex != -1) {
      final existingThread = updatedList[existingIndex];

      int newCount = existingThread.unRead ?? 0;

      if (event.useProvidedUnreadCount) {

        newCount = incomingThread.unRead ?? 0;
      } 
      else if (event.shouldResetCount) {
        newCount = 0; 
      } 
      else if (event.shouldIncrementCount) {
        // A real new message arrived — clear the read flag so the badge shows.
        _localReadThreadIds.remove(existingThread.id.toString());
        _persistReadIds();
        newCount = newCount + 1;
      }
      final mergedThread = existingThread.copyWith(
        unRead: newCount,
        lastMessage: incomingThread.lastMessage,
        isFile: incomingThread.isFile,
      );

      updatedList.removeAt(existingIndex);
      updatedList.insert(0, mergedThread);
      if (event.shouldIncrementCount) _pusherReorderedSinceLastFetch = true;
      
    } else {

      final int initialCount = event.useProvidedUnreadCount 
          ? (incomingThread.unRead ?? 0)
          : (event.shouldResetCount ? 0 : (event.shouldIncrementCount ? 1 : 0));

      final newThread = incomingThread.copyWith(
        unRead: initialCount,
      );

      updatedList.insert(0, newThread);
    }

    emit(state.copyWith(threads: updatedList));
  }

  
  
  
  
  void _onThreadRead(ThreadRead event, Emitter<MessagingState> emit) {
    // Remember this thread so future API fetches don't re-show stale counts.
    _localReadThreadIds.add(event.threadId.toString());
    _persistReadIds();

    final updatedThreads = state.threads.map((t) {
      if (t.id == event.threadId) {
        return t.copyWith(unRead: 0);
      }
      return t;
    }).toList();

    emit(state.copyWith(threads: updatedThreads));
  }

  Future<void> _onFetchGroupEvent(
    FetchGroupEvent event,
    Emitter<MessagingState> emit,
  ) async {
    emit(state.copyWith(groupsLoading: true, groupError: null));

    final cachedResult = await _getCachedGroups();
    cachedResult.fold((failure) {}, (groups) {
      if (groups.isNotEmpty) {
        final groupList = List<GroupEntity>.from(groups.reversed);
        emit(state.copyWith(groups: groupList, groupsLoading: true));
      }
    });

    final res = await _getJoinedGroups();
    res.fold(
      (failure) {
        emit(state.copyWith(groupsLoading: false, groupError: failure.message));
      },
      (groups) {
        final groupList = List<GroupEntity>.from(groups.reversed);
        emit(
          state.copyWith(
            groups: groupList,
            groupsLoading: false,
            groupError: null,
          ),
        );
      },
    );
  }

  void _onIncomingGroupMessage(
    IncomingGroupMessageEvent event,
    Emitter<MessagingState> emit,
  ) {
    final int index = state.groups.indexWhere(
      (g) => g.groupId == event.groupId,
    );

    if (index != -1) {
      final currentGroup = state.groups[index];

      final updatedGroup = currentGroup.copyWith(
        unreadCount: currentGroup.unreadCount + 1,
      );

      final updatedList = List<GroupEntity>.from(state.groups);

      updatedList.removeAt(index);
      updatedList.insert(0, updatedGroup);

      emit(state.copyWith(groups: updatedList));
    }
  }

  void _onGroupChatOpened(
    GroupChatOpenedEvent event,
    Emitter<MessagingState> emit,
  ) {
    final updatedList = state.groups.map((g) {
      if (g.groupId == event.groupId) {
        return g.copyWith(unreadCount: 0);
      }
      return g;
    }).toList();

    emit(state.copyWith(groups: updatedList));
  }

  Future<void> _onUserTyping(
    UserTypingEvent event,
    Emitter<MessagingState> emit,
  ) async {
     debugPrint("🔔 Bloc UserTyping: ${event.userId} -> ${event.isTyping}");
     debugPrint("🔎 Bloc Looking for Thread with UserID: '${event.userId}'");


    final index = state.threads.indexWhere((t) {
      final String threadUserId = (t.chatUserToId ?? "").toString().trim();
      final String targetId = event.userId.toString().trim();
      return threadUserId == targetId;
    });

    if (index != -1) {
      debugPrint("✅ FOUND Thread at index $index. Updating isTyping to ${event.isTyping}");
      final currentThread = state.threads[index];
      if (currentThread.isTyping == event.isTyping) return; 

      final updatedThread = currentThread.copyWith(isTyping: event.isTyping);
      final updatedList = List<MessageThread>.from(state.threads);
      updatedList[index] = updatedThread;

      emit(state.copyWith(threads: updatedList));
    } else {
       debugPrint("⚠️ UserTyping: Thread not found for ID ${event.userId}");
    }
  }
}
