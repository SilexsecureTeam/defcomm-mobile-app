import 'package:defcomm/core/theme/app_colors.dart';
import 'package:defcomm/features/chat_details/data/models/chat_user_model.dart';
import 'package:defcomm/features/chat_details/presentation/pages/chat_screen.dart';
import 'package:defcomm/features/messaging/presentation/model/story_contact.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/story.dart';

class StoriesList extends StatelessWidget {
  final List<Story> stories;
  const StoriesList({super.key, required this.stories});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Column(
      children: [
        SizedBox(
          height: screenHeight * 0.12,
          child: ListView.builder(
            padding: EdgeInsets.zero,
            scrollDirection: Axis.horizontal,
            itemCount: stories.length,
            itemBuilder: (context, index) {
              final story = stories[index];

              return GestureDetector(
                onTap: () {
                  if (story.contactIdEncrypt != null && story.name != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          user: ChatUser(
                            id: story.contactIdEncrypt!,
                            name: story.name ?? "Unknown",
                            imageUrl: story.imageUrl,
                            role: "user",
                          ),
                        ),
                      ),
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: screenHeight * 0.04,
                        backgroundColor: Colors.white24,
                        child: Text(_initialsFromFullName(story.name)),
                      ),

                      const SizedBox(height: 10),

                      SizedBox(
                        width: 80,
                        child: Text(
                          story.name ?? "Unnamed",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            stories.length,
            (index) => _buildDot(isActive: index == 0),
          ),
        ),
      ],
    );
  }

  Widget _buildDot({bool isActive = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      height: 4,
      width: 4,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
    );
  }
}

String _initialsFromFullName(String? fullName) {
  if (fullName == null || fullName.trim().isEmpty) return "G";

  final parts = fullName.trim().split(RegExp(r'\s+'));

  if (parts.length == 1) {
    return parts[0][0].toUpperCase();
  }

  final first = parts.first[0].toUpperCase();
  final last = parts.last[0].toUpperCase();

  return "$first$last";
}
