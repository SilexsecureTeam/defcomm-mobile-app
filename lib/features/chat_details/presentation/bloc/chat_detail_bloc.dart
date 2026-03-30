import 'package:defcomm/features/chat_details/domain/entities/chat_message.dart';
import 'package:defcomm/features/chat_details/domain/usecases/fetch_local_message.dart';
import 'package:get_storage/get_storage.dart';
import 'package:defcomm/features/chat_details/domain/usecases/fetch_messages.dart';
import 'package:defcomm/features/chat_details/domain/usecases/send_message.dart';
import 'package:defcomm/features/chat_details/presentation/bloc/chat_detail_event.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'chat_detail_state.dart';

class ChatDetailBloc extends Bloc<ChatDetailEvent, ChatDetailState> {
  final FetchMessages _fetchMessages;
  final SendMessage _sendMessage;

  final FetchLocalMessages _fetchLocalMessages;



  int _currentPage = 1;
  bool _isFetching = false;

  ChatDetailBloc({
    required FetchMessages fetchMessages,
    required SendMessage sendMessage,
    required FetchLocalMessages fetchLocalMessages,
    List<ChatMessage>? initialMessages, 
  }) : _fetchMessages = fetchMessages,
       _sendMessage = sendMessage,
       _fetchLocalMessages = fetchLocalMessages,
       super((initialMessages != null && initialMessages.isNotEmpty)
             ? ChatDetailLoaded(messages: initialMessages, hasReachedMax: false)
             : ChatDetailInitial()) {
    on<ChatReset>((event, emit) {
      _currentPage = 1;
      _isFetching = false;
      
      emit(ChatDetailInitial());
    });

    on<MessagesFetched>((event, emit) async {
      // Prevent duplicate requests
      if (_isFetching) return;

      _isFetching = true;
      final currentState = state;

      // -------------------------------------------------------------
      // 1. INSTANT LOCAL LOAD (Only on first page load)
      // -------------------------------------------------------------

       if (currentState is ChatDetailInitial) {
        // Show loading initially...
        emit(ChatDetailLoading());

        // Attempt to fetch local data immediately
        final localMsgs = await _fetchLocalMessages(event.chatUserId);
        
        if (localMsgs.isNotEmpty) {
          // Show local messages immediately while we wait for network
          emit(ChatDetailLoaded(
            messages: localMsgs,
            hasReachedMax: false, // We assume there might be more on server
          ));
        }
      }



      // Determine if we're fetching the first page or loading more
      if (currentState is ChatDetailInitial) {
        emit(ChatDetailLoading());
      }

      final res = await _fetchMessages(
        FetchMessagesParams(chatUserId: event.chatUserId, page: _currentPage),
      );

      // res.fold((failure) => emit(ChatDetailFailure(failure.message)), (
      //   chatPage,
      // ) {
      //   _currentPage++;
      //   if (currentState is ChatDetailLoaded) {
      //     // Append new messages to the existing list
      //     emit(
      //       currentState.copyWith(
      //         messages: List.of(currentState.messages)
      //           ..addAll(chatPage.messages),
      //         hasReachedMax: !chatPage.hasMorePages,
      //       ),
      //     );
      //   } else {
      //     // This is the first successful load
      //     emit(
      //       ChatDetailLoaded(
      //         messages: chatPage.messages,
      //         hasReachedMax: !chatPage.hasMorePages,
      //       ),
      //     );
      //   }
      // });

      res.fold(
        (failure) {
          // If we already have local data showing, don't show Error Screen.
          // Just show a Toast, or keep the current state.
          if (state is ChatDetailLoaded && (state as ChatDetailLoaded).messages.isNotEmpty) {
             // Optional: emit a side-effect or just debugPrint
             debugPrint("Background refresh failed: ${failure.message}");
          } else {
            emit(ChatDetailFailure(failure.message));
          }
        },
        (chatPage) {
          _currentPage++;
          if (state is ChatDetailLoaded) {
            // MERGE LOGIC:
            // Since we might have loaded local messages, and now we got server messages,
            // we should replace the duplicates or simply replace the list if it's page 1.
            
            List<ChatMessage> finalMessages;
            
            if (_currentPage - 1 == 1) {
                // Page-1 from server is the authoritative list.
                finalMessages = chatPage.messages;
            } else {
                // It's page 2+, just append
                finalMessages = List.of((state as ChatDetailLoaded).messages)
                  ..addAll(chatPage.messages);
            }
            
            emit(
              (state as ChatDetailLoaded).copyWith(
                messages: finalMessages,
                hasReachedMax: !chatPage.hasMorePages,
              ),
            );
          } else {
            emit(
              ChatDetailLoaded(
                messages: chatPage.messages,
                hasReachedMax: !chatPage.hasMorePages,
              ),
            );
          }
        },
      );
      _isFetching = false;
    });

    on<MessageSent>((event, emit) async {
      final currentState = state;
      if (currentState is! ChatDetailLoaded) return;

      final String myUserId = GetStorage().read('userEnId') ?? 'me';

      final optimisticMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        message: event.message,
        isMyChat: true,
        senderId: myUserId,
        createdAt: DateTime.now().toIso8601String(),
        isRead: false,
        isFile: false,
        status: MessageStatus.sending,
      );

      // 1) Add optimistic message at top
      final tempMessages = List<ChatMessage>.from(currentState.messages)
        ..insert(0, optimisticMessage);
      emit(currentState.copyWith(messages: tempMessages));

      // 2) Call API
      final res = await _sendMessage(
        SendMessageParams(
          message: event.message,
          isFile: false,
          chatUserType: 'user',
          currentChatUser: event.chatUserId,
        ),
      );

      res.fold(
        (failure) {
          // You might instead mark this message as failed instead of nuking the state
          emit(ChatDetailFailure(failure.message));
        },
        (sentMessage) {
          // 3) Replace optimistic with real message & set status = sent
          final finalMessages = List<ChatMessage>.from(tempMessages);

          final index = finalMessages.indexWhere(
            (msg) => msg.id == optimisticMessage.id,
          );

          if (index != -1) {
            finalMessages[index] = sentMessage.copyWith(
              status: MessageStatus.sent,
            );
          }

          emit(
            ChatDetailLoaded(
              messages: finalMessages,
              hasReachedMax: currentState.hasReachedMax,
            ),
          );
        },
      );
    });

    on<IncomingMessageEvent>((event, emit) {
      final msg = event.message;
      final currentState = state;

      if (currentState is ChatDetailLoaded) {
        // 1) If a message with same id already exists → update instead of inserting
        final existingIndex = currentState.messages.indexWhere(
          (m) => m.id == msg.id,
        );

        if (existingIndex != -1) {
          final updated = List<ChatMessage>.from(currentState.messages);
          updated[existingIndex] = msg; // update status, read flag, etc.
          emit(currentState.copyWith(messages: updated));
          return;
        }

        // 2) If it's *my* message and we've just done optimistic insert+API replace,
        //    it's possible ids differ. You can add a softer dedupe if needed:
        if (msg.isMyChat) {
          final softIndex = currentState.messages.indexWhere(
            (m) =>
                m.isMyChat &&
                m.message == msg.message &&
                (m.createdAt == msg.createdAt ||
                    (m.createdAt != null &&
                        msg.createdAt != null &&
                        m.createdAt!.substring(0, 16) ==
                            msg.createdAt!.substring(0, 16))),
          );
          if (softIndex != -1) {
            final updated = List<ChatMessage>.from(currentState.messages);
            updated[softIndex] = msg;
            emit(currentState.copyWith(messages: updated));
            return;
          }
        }
        final updated = List<ChatMessage>.from(currentState.messages)
          ..insert(0, msg);
        emit(currentState.copyWith(messages: updated));
      } else {
        // no messages yet
        emit(ChatDetailLoaded(messages: [msg], hasReachedMax: true));
      }
    });

    on<UpdateTypingEvent>((event, emit) {
      final currentState = state;
      if (currentState is ChatDetailLoaded) {
        emit(currentState.copyWith(isTyping: event.isTyping));
      }
    });

    on<LoadCachedMessages>((event, emit) {
      if (event.messages.isNotEmpty) {
        emit(ChatDetailLoaded(
          messages: event.messages,
          hasReachedMax: false,
        ));
      }
    });
  }

  
 
}
