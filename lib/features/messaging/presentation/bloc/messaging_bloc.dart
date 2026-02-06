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
import 'package:flutter/material.dart';

class MessagingBloc extends Bloc<MessagingEvent, MessagingState> {
  final FetchStories _fetchStories;
  final FetchMessageThreads _fetchMessageThreads;
  final GetMessageJoinedGroups _getJoinedGroups;

  final GetCachedStories _getCachedStories;
  final GetCachedMessageThreads _getCachedThreads;
  final GetCachedGroups _getCachedGroups;

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
      if (threads.isNotEmpty) {
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

  // Future<void> _onNewThreadCreated(
  //   NewThreadCreatedEvent event,
  //   Emitter<MessagingState> emit,
  // ) async {
  //   final incomingThread = event.thread;

  //   final existingIndex = state.threads.indexWhere((t) {
      
  //     // A. Check Thread ID (Primary Key)
  //     if (t.id.toString() == incomingThread.id.toString()) return true;

  //     // B. Check Chat ID (If available)
  //     if (t.chatId != null && incomingThread.chatId != null) {
  //       if (t.chatId.toString() == incomingThread.chatId.toString()) return true;
  //     }

  //     // C. Check Conversation Partners (The most reliable for 1-on-1)
  //     // "Is this a chat with the same person?"
  //     if (t.chatUserToId != null && incomingThread.chatUserToId != null) {
  //       if (t.chatUserToId.toString() == incomingThread.chatUserToId.toString()) return true;
  //     }

  //     return false;
  //   });

  //   // Create a modifiable copy of the list
  //   final updatedList = List<MessageThread>.from(state.threads);

  //   if (existingIndex != -1) {
  //     // --- ✅ UPDATE EXISTING THREAD ---
  //     final existingThread = updatedList[existingIndex];

  //     // Calculate unread count logic
  //     int newCount = existingThread.unRead ?? 0;
  //     if (event.shouldResetCount) {
  //       newCount = 0; 
  //     } else if (event.shouldIncrementCount) {
  //       newCount = newCount + 1;
  //     }

  //     // Merge Data
  //     // We use 'existingThread' as the base to PRESERVE the correct name/image
  //     // We only overwrite the 'lastMessage', 'isFile', and 'unRead' from incoming.
  //     final mergedThread = existingThread.copyWith(
  //       unRead: newCount,
  //       lastMessage: incomingThread.lastMessage,
  //       isFile: incomingThread.isFile,
  //       // Don't overwrite name/image unless necessary logic dictates it
  //     );

  //     // Move to Top (Since it has a new message)
  //     updatedList.removeAt(existingIndex);
  //     updatedList.insert(0, mergedThread);
      
  //   } else {
  //     // --- 🆕 NEW THREAD ---
  //     final newThread = incomingThread.copyWith(
  //       unRead: event.shouldResetCount ? 0 : (event.shouldIncrementCount ? 1 : 0),
  //     );

  //     updatedList.insert(0, newThread);
  //   }

  //   emit(state.copyWith(threads: updatedList));
  // }

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
        newCount = newCount + 1;
      }
      final mergedThread = existingThread.copyWith(
        unRead: newCount,
        lastMessage: incomingThread.lastMessage,
        isFile: incomingThread.isFile,
      );

      updatedList.removeAt(existingIndex);
      updatedList.insert(0, mergedThread);
      
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
