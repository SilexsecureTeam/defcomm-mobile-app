import 'package:defcomm/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; 
import '../../domain/entities/chat_message.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
   final bool isHidden;
  // final VoidCallback onToggleHidden;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMe, required this.isHidden, 
    // required this.onToggleHidden,
  });

  @override
  Widget build(BuildContext context) {

    String formatTimestamp(String? isoString) {
      if (isoString == null) {
        return '';
      }
      try {
        final dateTime = DateTime.parse(isoString).toLocal();
        return DateFormat('HH:mm').format(dateTime); // Format to "14:35"
      } catch (e) {
        return '';
      }
    }

    final bubbleColor = isMe ? Colors.blueAccent : Colors.grey.shade800;
    final textColor = Colors.white;

    final contentText = isHidden ? 'xxxxxxxxxxxxxx' : (message.message ?? '');


    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? Colors.white : AppColors.tertiaryGreen, 
        borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            // bottomLeft:const Radius.circular(20) : Radius.zero,
            bottomRight: const Radius.circular(20),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end, 
        mainAxisSize: MainAxisSize.max, 
        children: [
          Expanded(
            child: Text(
              contentText,
              style: GoogleFonts.poppins(
                color: isMe ? Colors.black : Colors.white,
                fontSize: 14,
              ),
            ),
          ),
         

          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
              formatTimestamp(message.createdAt),
                style: GoogleFonts.poppins(
                  color: isMe ? Colors.black54 : Colors.white70,
                  fontSize: 12,
                ),
              ),
              if (isMe) ...[
                const SizedBox(height: 2),
                _buildStatusIcon(message),
              ],


            //    GestureDetector(
            //   onTap: onToggleHidden,
            //   child: Icon(
            //     isHidden ? Icons.visibility_off : Icons.visibility,
            //     size: 18,
            //     color: AppColors.quickAction1,
            //   ),
            // ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildStatusIcon(ChatMessage message) {
  if (!message.isMyChat) return SizedBox.shrink();

  switch (message.status) {
    case MessageStatus.sending:
      return Icon(Icons.access_time, size: 14, color: Colors.white54);
    case MessageStatus.sent:
      return Icon(Icons.check, size: 16, color: AppColors.quickAction1);
    case MessageStatus.delivered:
      return Icon(Icons.check, size: 16, color: Colors.white);
    case MessageStatus.read:
      return Icon(Icons.check, size: 16, color: Colors.lightBlueAccent);
    default:
      return SizedBox.shrink();
  }
}

}