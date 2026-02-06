import 'dart:math' as math;

import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:defcomm/core/theme/app_colors.dart';
import 'package:defcomm/features/home/presentation/pages/home_screen.dart';
import 'package:defcomm/features/messaging/presentation/pages/messaging_screen.dart';
import 'package:defcomm/features/profile/presentation/pages/profile.dart';
import 'package:defcomm/features/recent_calls/presentation/pages/recent_calls_screen.dart';
import 'package:defcomm/features/settings/presentation/pages/settings.dart';
import 'package:flutter/material.dart';


class HomeNavr extends StatefulWidget {
  final int initialIndex; 

  const HomeNavr({super.key, this.initialIndex = 0});

  @override
  State<HomeNavr> createState() => _HomeNavrState();
}

class _HomeNavrState extends State<HomeNavr> {
  late List<Widget> pages;
  late HomeScreen home;
  late MessagingScreen message;
  late RecentCallsScreen call_log;
  late Profile profile;
  late Settings settings;

  late int curentTabIndex; 

  @override
  void initState() {
    super.initState();
    curentTabIndex = widget.initialIndex; 

    home = HomeScreen();
    message = MessagingScreen();
    call_log = RecentCallsScreen();
    settings = Settings();
    profile = Profile();

    pages = [home, message, call_log, profile, settings];
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final double navBarHeight = math.min(screenHeight * 0.08, 75.0);
    
    return Scaffold(
      backgroundColor: AppColors.tertiaryGreen,
      bottomNavigationBar: CurvedNavigationBar(
        height: navBarHeight,
        
        index: curentTabIndex, 
        
        backgroundColor: Colors.transparent,
        color: Colors.black,
        buttonBackgroundColor: Colors.transparent,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        onTap: (int index) {
          setState(() {
            curentTabIndex = index;
          });
        },
        items: <Widget>[
          Image.asset("images/target.png"),
          Image.asset("images/Messaging.png", height: 25, width: 25),
          Image.asset("images/phone_call.png", height: 25, width: 25),
          Image.asset("images/user.png", height: 25, width: 25),
          Image.asset("images/settings_icon.png", height: 25, width: 25),
        ],
      ),
      body: IndexedStack(
        index: curentTabIndex,
        children: pages, 
      ),
      // pages[curentTabIndex],
    );
  }
}