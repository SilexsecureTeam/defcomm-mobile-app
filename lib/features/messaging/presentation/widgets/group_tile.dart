import 'package:defcomm/features/chat_details/data/models/chat_user_model.dart';
import 'package:defcomm/features/chat_details/presentation/pages/chat_screen.dart';
import 'package:defcomm/features/group_chat/presentation/bloc/group_chat_bloc.dart';
import 'package:defcomm/features/group_chat/presentation/pages/group_chat_screen.dart';
import 'package:defcomm/features/groups/domain/entities/group_entity.dart';
import 'package:defcomm/features/groups/presentation/bloc/group_mebers_event.dart';
import 'package:defcomm/features/groups/presentation/bloc/group_member_bloc.dart';
import 'package:defcomm/features/messaging/domain/entities/message_group_entity.dart';
import 'package:defcomm/features/messaging/domain/entities/message_thread.dart';
import 'package:defcomm/features/messaging/presentation/bloc/messaging_bloc.dart';
import 'package:defcomm/features/messaging/presentation/bloc/messaging_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../init_dependencies.dart';

class GroupTile extends StatelessWidget {
  final GroupEntity group;
  const GroupTile({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
       onTap: () {
        debugPrint("group id: ${group.groupId}");
        context.read<MessagingBloc>().add(GroupChatOpenedEvent(groupId: group.groupId));

         Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MultiBlocProvider(
                        providers: [
                          
                          BlocProvider<GroupChatBloc>.value(
                            value: serviceLocator<GroupChatBloc>(),
                          ),

                          BlocProvider(
                            create: (_) =>
                                serviceLocator<GroupMembersBloc>()
                                  ..add(FetchGroupMembers(group.groupId)),
                          ),
                        ],
                        child: GroupChatScreen(
                          groupIdEn: group
                              .groupId, 
                          groupName: group.groupName,
                          group: group,
                        ),
                      ),
                    ),
                  );
      
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                backgroundColor: Colors.white24,
                child: Text(
                  group.groupName.isNotEmpty
                      ? group.groupName[0].toUpperCase()
                      : 'G',
                ),
              ),
                
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.groupName?? "unnamed",
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
                  ),
                  
                ],
              ),
            ),
             if (group.unreadCount > 0)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.green, // WhatsApp Green
                  shape: BoxShape.circle,
                ),
                child: Text(
                  "${group.unreadCount}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
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