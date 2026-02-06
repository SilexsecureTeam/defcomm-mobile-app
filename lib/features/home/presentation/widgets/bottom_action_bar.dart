
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color kDarkGreen = Color(0xFF2C390A);

class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildBarButton(
            text: 'SECURE MODE',
            url: "images/secure_mode_2.png"
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildBarButton(
            text: 'ALL APPLICATIONS',
            icon: Icons.apps,
            url: ""
          ),
        ),
      ],
    );
  }

  Widget _buildBarButton({required String text,  IconData? icon, String? url}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: kDarkGreen,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          url!.isEmpty  ? Icon(icon, color: Colors.white, size: 20) : Image.asset(url),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 10),
          ),
        ],
      ),
    );
  }
}