import 'package:defcomm/core/theme/app_colors.dart';
import 'package:defcomm/features/app_navigation/presentation/pages/home_navr.dart';
import 'package:defcomm/features/messaging/presentation/bloc/messaging_bloc.dart';
import 'package:defcomm/features/messaging/presentation/bloc/messaging_state.dart';
import 'package:defcomm/features/messaging/presentation/pages/messaging_screen.dart';
import 'package:defcomm/features/recent_calls/presentation/pages/recent_calls_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';

class SecureCommsWidget extends StatelessWidget {
  const SecureCommsWidget({super.key, this.activeIconUrl, required this.showAllButton, required this.showNameText, required this.showBar});
  final String? activeIconUrl;
  final bool showAllButton;
  final bool showNameText;
  final bool showBar;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showNameText)
          Text(
            'SECURE COMMUNICATIONS',
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        const SizedBox(height: 5),
        Row(
          children: [
            Column(
              children: [
                SizedBox(height: 10,),
                if(showBar)
                  Container(width: 4, height: 60, color: AppColors.secureCommsVerticalBar),
              ],
            ),
            const SizedBox(width: 5),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: AppColors.vectorsBacgroundContainerColor
                  ),
                  child: Row(
                    children: [
                      BlocBuilder<MessagingBloc, MessagingState>(
                        builder: (context, msgState) {
                          final unread = msgState.threads.fold(0, (s, t) => s + (t.unRead ?? 0)) +
                              msgState.groups.fold(0, (s, g) => s + g.unreadCount);
                          return _buildComm(
                            context,
                            "images/Messaging.png",
                            showBadge: unread > 0,
                            onTap: () {
                              if (ModalRoute.of(context)?.settings.name != '/messaging') {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const HomeNavr(initialIndex: 1),
                                  ),
                                  (route) => false,
                                );
                              }
                            },
                          );
                        },
                      ),
                      Builder(builder: (context) {
                        final missedCalls = GetStorage().read<int>('missed_calls_badge') ?? 0;
                        return _buildComm(
                          context,
                          "images/phone_call.png",
                          showBadge: missedCalls > 0,
                          onTap: () {
                            if (ModalRoute.of(context)?.settings.name != '/recent_calls') {
                              GetStorage().write('missed_calls_badge', 0);
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HomeNavr(initialIndex: 2),
                                ),
                                (route) => false,
                              );
                            }
                          },
                        );
                      }),
                      _buildComm(context, "images/Drive.png", onTap:  () {}),
                      _buildComm(context, "images/Email.png", onTap: () {}),
                      _buildComm(context, "images/Browser.png", onTap: () {}),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (showAllButton)
          Row(
            mainAxisAlignment: MainAxisAlignment.end, 
            children: [
              TextButton(
                onPressed: () {},
                child: Text(
                  'Show All',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white, 
                    fontWeight: FontWeight.w400,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white,
                  ),
                ),
              ),
            ],
          )
      ],
    );
  }

  Widget _buildComm(BuildContext context, String url, {VoidCallback? onTap, bool showBadge = false}) {
    final bool isActive = url == activeIconUrl;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 12.0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: isActive ? Colors.white : AppColors.secureCommsVerticalBar,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Image.asset(url, height: 30, width: 30,
                    color: isActive ? AppColors.secureCommsVerticalBar : null),
              ),
            ),
            if (showBadge)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}