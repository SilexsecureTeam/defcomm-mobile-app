import 'package:defcomm/features/secure_comms/data/models/inviter.dart';
import 'package:defcomm/features/secure_comms/data/models/otp_details_model.dart';
import 'package:flutter/material.dart';

enum GroupStatusType { pending, joined, error }

class GroupStatus {
  final GroupStatusType type;

  GroupStatus({
    required this.type,
  });


  IconData get iconData {
    switch (type) {
      case GroupStatusType.pending:
        return Icons.check; 
      case GroupStatusType.joined:
        return Icons.priority_high; 
      case GroupStatusType.error:
        return Icons.close;
    }
  }

  Color get iconSymbolColor {
     return Colors.black; 
  }

  Color get iconBackgroundColor {
    switch (type) {
      case GroupStatusType.pending:
        return const Color(0xFF16C60C); 
      case GroupStatusType.joined:
        return const Color(0xFFF9F104); 
      case GroupStatusType.error:
        return const Color(0xFFE81123); 
    }
  }
  
  Color get gradientStartColor {
     switch (type) {
      case GroupStatusType.pending:
        return const Color(0xFF004D40);
      case GroupStatusType.joined:
        return const Color(0xFF4B342A);
      case GroupStatusType.error:
        return const Color(0xFF4A2534);
    }
  }
}