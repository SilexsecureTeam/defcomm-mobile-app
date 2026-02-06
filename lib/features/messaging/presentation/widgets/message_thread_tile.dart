import 'package:defcomm/features/chat_details/data/datasources/chat_detail_local_data_source.dart';
import 'package:defcomm/features/chat_details/data/models/chat_user_model.dart';
import 'package:defcomm/features/chat_details/presentation/bloc/chat_detail_bloc.dart';
import 'package:defcomm/features/chat_details/presentation/bloc/chat_detail_event.dart';
import 'package:defcomm/features/chat_details/presentation/pages/chat_screen.dart';
import 'package:defcomm/features/messaging/domain/entities/message_thread.dart';
import 'package:defcomm/features/messaging/presentation/bloc/messaging_bloc.dart';
import 'package:defcomm/features/messaging/presentation/bloc/messaging_event.dart';
import 'package:defcomm/init_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class MessageThreadTile extends StatelessWidget {
  final MessageThread thread;
  const MessageThreadTile({super.key, required this.thread});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      

      onTap: () {
        context.read<MessagingBloc>().add(ThreadRead(thread.id!));

        if (thread.chatUserToId != null && thread.chatUserToName != null) {
          final chatUser = ChatUser(
            id: thread.chatUserToId.toString(),
            name: thread.chatUserToName!,
            imageUrl: thread.imageUrl,
            role: thread.chatUserType ?? 'user',
          );


          final dataSource = serviceLocator<ChatDetailLocalDataSource>();

          final cachedMessages = dataSource.getLocalMessagesSync(chatUserId: chatUser.id);

          final chatBloc = ChatDetailBloc(
            fetchMessages: serviceLocator(),
            sendMessage: serviceLocator(),
            fetchLocalMessages: serviceLocator(), 
            initialMessages: cachedMessages, 
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(user: chatUser)
              
            ),
          )
          .then((_) {
            if (context.mounted) {
              context.read<MessagingBloc>().add(
                FetchMessageThreadsEvent(markedReadThreadId: thread.id),
              );
            }
          });
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.transparent,
                  backgroundImage: AssetImage(thread.imageUrl),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        thread.chatUserToName ?? "unnamed",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      if ((thread.unRead ?? 0) > 0)
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.redAccent,
                          child: Text(
                            _formatUnreadCount(thread.unRead),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  thread.isTyping
                      ? Text(
                          "${thread.chatUserToName ?? ""} is typing...",
                          style: GoogleFonts.poppins(
                            color: Colors.greenAccent,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      : Text(
                          thread.isFile == 'yes'
                              ? '[Attachment]'
                              : '********************',
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          style: GoogleFonts.poppins(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                        ),
                ],
              ),
            ),
            Text(
              "",
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatUnreadCount(int? count) {
  if (count == null || count <= 0) return "";
  if (count > 99) return "99+";
  return count.toString();
}
