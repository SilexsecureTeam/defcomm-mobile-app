import 'package:defcomm/core/theme/app_colors.dart';
import 'package:defcomm/features/app_navigation/presentation/pages/home_navr.dart';
import 'package:defcomm/features/messaging/presentation/pages/messaging_screen.dart';
import 'package:defcomm/features/recent_calls/presentation/pages/recent_calls_screen.dart';
import 'package:flutter/material.dart';
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
                      _buildComm(context, "images/Messaging.png", onTap: () {
        if (ModalRoute.of(context)?.settings.name != '/messaging') {
          // Navigator.of(context).push(
          //   MaterialPageRoute(
          //     builder: (context) => const MessagingScreen(),
          //     settings: const RouteSettings(name: '/messaging'),
          //   ),
          // );

          Navigator.pushAndRemoveUntil(
                context, 
                MaterialPageRoute(
                  builder: (context) => const HomeNavr(initialIndex: 1),
                ),
                (route) => false, 
              );
        }
      },),
                      _buildComm(context,"images/phone_call.png", onTap: () {
            if (ModalRoute.of(context)?.settings.name != '/recent_calls') {
              Navigator.pushAndRemoveUntil(
                context, 
                MaterialPageRoute(
                  builder: (context) => const HomeNavr(initialIndex: 2),
                ),
                (route) => false, 
              );
                // Navigator.of(context).push(
                //   MaterialPageRoute(
                //     builder: (context) => const RecentCallsScreen(),
                //     settings: const RouteSettings(name: '/recent_calls'),
                //   ),
                // );
            }
          },),
          
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

  Widget _buildComm( BuildContext context, String url, {VoidCallback? onTap}) {
    final bool isActive = url == activeIconUrl;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 12.0),
        child: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color:isActive ? Colors.white :  AppColors.secureCommsVerticalBar,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: Image.asset(url, height: 30, width: 30, color: isActive ? AppColors.secureCommsVerticalBar : null)),
        ),
      ),
    );
  }
}