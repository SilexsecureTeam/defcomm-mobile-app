import 'package:defcomm/features/secure_comms/data/models/inviter.dart';
import 'package:defcomm/features/secure_comms/data/models/otp_details_model.dart';
import 'package:flutter/material.dart';

enum NotificationType { success, warning, error }

class AppNotification {
  final String title;
  final String subtitle;
  final NotificationType type;
  final Inviter? inviter;
  final OtpDetails? otpDetails;

  AppNotification({
    required this.title,
    required this.subtitle,
    required this.type,
    this.inviter,
    this.otpDetails,
  });


  IconData get iconData {
    switch (type) {
      case NotificationType.success:
        return Icons.check; 
      case NotificationType.warning:
        return Icons.priority_high; 
      case NotificationType.error:
        return Icons.close;
    }
  }

  Color get iconSymbolColor {
     return Colors.black; 
  }

  Color get iconBackgroundColor {
    switch (type) {
      case NotificationType.success:
        return const Color(0xFF16C60C); 
      case NotificationType.warning:
        return const Color(0xFFF9F104); 
      case NotificationType.error:
        return const Color(0xFFE81123); 
    }
  }
  
  Color get gradientStartColor {
     switch (type) {
      case NotificationType.success:
        return const Color(0xFF004D40);
      case NotificationType.warning:
        return const Color(0xFF4B342A);
      case NotificationType.error:
        return const Color(0xFF4A2534);
    }
  }
}