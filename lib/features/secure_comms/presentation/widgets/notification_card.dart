import 'package:defcomm/features/secure_comms/data/models/notification_model.dart';
import 'package:defcomm/features/secure_comms/presentation/widgets/invitation_modal_content.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';



class NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final bool isExpanded;
  final VoidCallback onTap;

  const NotificationCard({super.key, required this.notification, required this.isExpanded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const Color gradientEndColor = Color(0xFF242C32);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            notification.gradientStartColor,
            gradientEndColor,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          stops: const [0.0, 0.3], 
        ),
        borderRadius: BorderRadius.circular(16),
        border: isExpanded ? Border.all(color: Colors.greenAccent, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: notification.iconBackgroundColor.withOpacity(0.1),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: notification.iconBackgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    notification.iconData,
                    color: notification.iconSymbolColor,
                    size: 10, 
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.subtitle,
                      style: GoogleFonts.poppins(
                        color: Color(0xffC8C5C5),
                        fontSize: 14,
                        fontWeight: FontWeight.w400
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}