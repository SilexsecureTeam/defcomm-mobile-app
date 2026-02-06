// ignore_for_file: library_private_types_in_public_api

import 'package:defcomm/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// class AppColors {
//   static const Color lightGreen = Color(0xFFA1C13B);
//   static const Color backgroundGreen = Color(0xFF2C390A);
// }


class AnimatedChecklistItem extends StatefulWidget {
  final String text;
  final Duration delay;

  const AnimatedChecklistItem({
    super.key,
    required this.text,
    required this.delay,
  });

  @override
  _AnimatedChecklistItemState createState() => _AnimatedChecklistItemState();
}

class _AnimatedChecklistItemState extends State<AnimatedChecklistItem> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() {
          _isVisible = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: _isVisible ? 1.0 : 0.0,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          children: [
            // The checkmark icon
            Container(
              width: 20,
              height: 20,
              decoration:  BoxDecoration(
                color: AppColors.backgroundGreen,
                shape: BoxShape.circle,
              ),
              child:  Center(
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 10,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                widget.text,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}