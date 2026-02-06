import 'package:defcomm/features/group_chat/domain/entities/group_chat_message.dart';
import 'package:flutter/material.dart';

class GroupCallInviteBubble extends StatelessWidget {
  final GroupChatMessage message;
  final VoidCallback onJoin;
   final bool isEnded;

  const GroupCallInviteBubble({
    Key? key,
    required this.message,
    required this.onJoin,
    this.isEnded = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMyChat;

    final now = DateTime.now();
    final msgTime = DateTime.tryParse(message.createdAt) ?? now;
    // Expire call bubble after 60 mins
    final isTimeExpired = now.difference(msgTime).inMinutes > 60; 


     final isExpired = isTimeExpired || isEnded;

 
    final bool showJoinButton = !isExpired && !isMe;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        width: 250,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF005C4B) : const Color(0xFF1F2C34),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
             Row(
               children: [
                 Container(
                   padding: const EdgeInsets.all(8),
                   decoration: BoxDecoration(
                     color: isExpired ? Colors.grey.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                     shape: BoxShape.circle,
                   ),
                   child: Icon(
                     isMe ? Icons.call_made : Icons.call_received, 
                     color: isExpired ? Colors.grey : Colors.green
                   ),
                 ),
                 const SizedBox(width: 12),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         isExpired 
                           ? "Voice call ended" 
                           : (isMe ? "You started a call" : "Incoming Group Call"),
                         style: TextStyle(
                           color: isExpired ? Colors.white54 : Colors.white,
                           fontWeight: FontWeight.bold,
                           fontSize: 15,
                         ),
                       ),
                       const SizedBox(height: 4),
                       Text(
                         message.createdAt.split('T').last.substring(0, 5),
                         style: const TextStyle(color: Colors.white54, fontSize: 12),
                       ),
                     ],
                   ),
                 ),
               ],
             ),
             
             if (showJoinButton) ...[
               const SizedBox(height: 12),
               SizedBox(
                 width: double.infinity,
                 child: ElevatedButton(
                   onPressed: onJoin,
                   style: ElevatedButton.styleFrom(
                     backgroundColor: const Color(0xFF00A884),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                     padding: const EdgeInsets.symmetric(vertical: 10),
                   ),
                   child: const Text(
                     "Join Call", 
                     style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                   ),
                 ),
               ),
             ]
          ],
        ),
      ),
    );
  }
}