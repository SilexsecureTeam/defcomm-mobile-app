// lib/features/group_chat/presentation/bloc/group_chat_bloc.dart
import 'package:defcomm/features/group_chat/data/models/group_chat_message_model.dart';
import 'package:defcomm/features/group_chat/domain/entities/group_chat_message.dart';
import 'package:defcomm/features/group_chat/domain/usecases/fetch_group_messages.dart';
import 'package:defcomm/features/group_chat/domain/usecases/fetch_local_group_messages.dart';
import 'package:defcomm/features/group_chat/domain/usecases/send_group_message.dart';
import 'package:defcomm/features/group_chat/presentation/bloc/group_chat_event.dart';
import 'package:defcomm/features/group_chat/presentation/bloc/group_chat_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GroupChatBloc extends Bloc<GroupChatEvent, GroupChatState> {
  final FetchGroupMessages _fetchGroupMessages;
  final SendGroupMessage _sendGroupMessage;
  final FetchLocalGroupMessages _fetchLocalGroupMessages;

  int _currentPage = 1;
  bool _isFetching = false;
  String? _currentGroupUserIdEn; // track which group we’re in

  GroupChatBloc({
    required FetchGroupMessages fetchGroupMessages,
    required SendGroupMessage sendGroupMessage,
    required FetchLocalGroupMessages fetchLocalGroupMessages,
  }) : _fetchGroupMessages = fetchGroupMessages,
       _sendGroupMessage = sendGroupMessage,
       _fetchLocalGroupMessages = fetchLocalGroupMessages,
       super(GroupChatInitial()) {
    on<GroupMessagesFetched>(_onFetchMessages);
    on<GroupMessageSent>(_onSendMessage);
    on<GroupReplySelected>(_onReplySelected);
    on<GroupReplyCleared>(_onReplyCleared);

    on<GroupIncomingMessageReceived>(_onIncomingMessage);
  }

  Future<void> _onFetchMessages(
    GroupMessagesFetched event,
    Emitter<GroupChatState> emit,
  ) async {
    // If user switches to a different group, reset pagination
    if (_currentGroupUserIdEn != event.groupUserIdEn) {
      _currentGroupUserIdEn = event.groupUserIdEn;
      _currentPage = 1;
      _isFetching = false;

      // Optionally reset state:
      // if (state is! GroupChatInitial) {
      //   emit(GroupChatInitial());
      // }
    }

    if (_isFetching) return;
    _isFetching = true;

    final currentState = state;

    if (currentState is GroupChatInitial) {
      emit(GroupChatLoading());

      final localMsgs = await _fetchLocalGroupMessages(event.groupUserIdEn);
      if (localMsgs.isNotEmpty) {
        emit(GroupChatLoaded(messages: localMsgs, hasReachedMax: false));
      }
    }

    final res = await _fetchGroupMessages(
      FetchGroupMessagesParams(
        groupUserIdEn: event.groupUserIdEn,
        page: _currentPage,
      ),
    );

    res.fold(
      (failure) {
        // emit(GroupChatFailure(failure.message));
        if (state is GroupChatLoaded &&
            (state as GroupChatLoaded).messages.isNotEmpty) {
          // Maybe debug print error, but keep showing cache
        } else {
          emit(GroupChatFailure(failure.message));
        }
      },
      (page) {
        _currentPage++;

        if (state is GroupChatLoaded) {
          final currentMsgs = (state as GroupChatLoaded).messages;

          List<GroupChatMessage> newMsgList;
          if (_currentPage - 1 == 1) {
            newMsgList = page.messages; 
          } else {
            newMsgList = List.from(currentMsgs)..addAll(page.messages);
          }

          emit(
            (state as GroupChatLoaded).copyWith(
              messages: newMsgList,
              hasReachedMax: !page.hasMorePages,
            ),
          );
        } else {
          emit(
            GroupChatLoaded(
              messages: page.messages,
              hasReachedMax: !page.hasMorePages,
            ),
          );
        }

        // if (currentState is GroupChatLoaded) {
        //   // Append new page
        //   emit(
        //     currentState.copyWith(
        //       messages: List<GroupChatMessage>.from(currentState.messages)
        //         ..addAll(page.messages),
        //       hasReachedMax: !page.hasMorePages,
        //       replyTo: currentState.replyTo,
        //     ),
        //   );
        // } else {
        //   // First load
        //   emit(
        //     GroupChatLoaded(
        //       messages: page.messages,
        //       hasReachedMax: !page.hasMorePages,
        //     ),
        //   );
        // }
      },
    );

    _isFetching = false;
  }

  Future<void> _onSendMessage(
    GroupMessageSent event,
    Emitter<GroupChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is! GroupChatLoaded) return;

    final replyTo = currentState.replyTo;

    const myUserId = 'me';
    const myUserName = 'You';

    final optimistic = GroupChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      isMyChat: true,
      senderId: myUserId,
      senderName: myUserName,
      groupId: event.groupUserIdEn,
      message: event.message,
      createdAt: DateTime.now().toIso8601String(),
      isFile: false,
      isRead: false,
      fileType: 'other',
      tagUserId: replyTo?.senderId,
      tagMessageId: replyTo?.id,
      tagMessageUserId: replyTo?.senderId,
      tagMessageIsMyChat: replyTo?.isMyChat,
      tagMessageText: replyTo?.message,
    );

    final updated = List<GroupChatMessage>.from(currentState.messages)
      ..insert(0, optimistic);

    emit(currentState.copyWith(messages: updated, replyTo: null));

    final res = await _sendGroupMessage(
      SendGroupMessageParams(
        currentChatUser: event.groupUserIdEn,
        message: event.message,
        isFile: false,
        mssType: 'text',
        tagUserIds: event.tagUserIds,
        tagMessageId: replyTo?.id,
      ),
    );

    res.fold(
      (failure) {
        emit(GroupChatFailure(failure.message));
      },
      (sent) {
        final fixed = List<GroupChatMessage>.from(updated);
        final idx = fixed.indexWhere((m) => m.id == optimistic.id);
        if (idx != -1) {
          fixed[idx] = sent;
        } else {
          fixed.insert(0, sent);
        }

        emit(currentState.copyWith(messages: fixed, replyTo: null));
      },
    );
  }

  void _onReplySelected(
    GroupReplySelected event,
    Emitter<GroupChatState> emit,
  ) {
    final currentState = state;
    if (currentState is! GroupChatLoaded) return;

    emit(currentState.copyWith(replyTo: event.message));
  }

  void _onReplyCleared(GroupReplyCleared event, Emitter<GroupChatState> emit) {
    final currentState = state;
    if (currentState is! GroupChatLoaded) return;

    emit(currentState.copyWith(replyTo: null));
  }

  void _onIncomingMessage(
    GroupIncomingMessageReceived event,
    Emitter<GroupChatState> emit,
  ) {
    debugPrint("Bloc: Received GroupIncomingMessageReceived");
    
    final currentState = state;

    if (currentState is! GroupChatLoaded) {
       debugPrint("Bloc: State is not Loaded (${currentState.runtimeType}). Ignoring message.");
       return;
    }

    try {
      final map = Map<String, dynamic>.from(event.payload);
      final msg = GroupChatMessageModel.fromJson(map); // Parsed message

      final content = msg.message ?? "";
      final String signalSenderId = msg.senderId ?? "";

      if (content.contains("__DEFCOMM_GROUP_CALL_ENDED_v1__")) {
        
        String? targetInviteId;

        try {
        
          final inviteMsg = currentState.messages.firstWhere((existingMsg) {
             final existingContent = existingMsg.message ?? "";
             
             final bool isInvite = existingContent.contains("videoSdkRoomId") || existingContent.contains("Room ID:"); 
                          return isInvite && existingMsg.senderId == signalSenderId;
          });
          targetInviteId = inviteMsg.id;
        } catch (_) {
        }

        if (targetInviteId != null) {
          
          final newEndedSet = Set<String>.from(currentState.endedCallIds)..add(targetInviteId);

          emit(currentState.copyWith(endedCallIds: newEndedSet));
        }
        
        return; 
      }

      if (currentState.messages.any((m) => m.id == msg.id)) {
        return;
      }

      final updatedMessages = List<GroupChatMessage>.from(currentState.messages)
        ..insert(0, msg);

      emit(currentState.copyWith(
        messages: updatedMessages,
        hasReachedMax: currentState.hasReachedMax,
        replyTo: currentState.replyTo,
        taggedUserIds: currentState.taggedUserIds,
        endedCallIds: currentState.endedCallIds, 
      ));
      
      
    } catch (e, stack) {
      debugPrint(stack.toString());
    }
  }
}
