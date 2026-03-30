import 'dart:async';
import 'dart:math' as math;

import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:defcomm/features/messaging/presentation/bloc/messaging_bloc.dart';
import 'package:defcomm/features/messaging/presentation/bloc/messaging_state.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:defcomm/core/services/oem_battery_service.dart';
import 'package:defcomm/features/app_drawer/presentation/pages/app_drawer_screen.dart';
import 'package:defcomm/features/home/presentation/pages/tactical_home_screen.dart';
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
  late TacticalHomeScreen home;
  late MessagingScreen message;
  late RecentCallsScreen call_log;
  late Profile profile;
  late Settings settings;
  late AppDrawerScreen appDrawer;

  late int curentTabIndex; 
  int _missedCallsBadge = 0;
  VoidCallback? _callBadgeSub;

  @override
  void initState() {
    super.initState();
    curentTabIndex = widget.initialIndex;

    // Lock to immersive sticky — hides status + nav bars (kiosk mode).
    // Re-applied on every build to survive OS restoring the bars.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    home = TacticalHomeScreen(
      onNavigateToTab: (index) {
        setState(() => curentTabIndex = index);
      },
    );
    message = MessagingScreen();
    call_log = RecentCallsScreen();
    settings = Settings();
    profile = Profile();
    appDrawer = const AppDrawerScreen();

    pages = [home, message, call_log, appDrawer, profile, settings];

    _missedCallsBadge = GetStorage().read<int>('missed_calls_badge') ?? 0;
    _callBadgeSub = GetStorage().listenKey('missed_calls_badge', (val) {
      if (mounted) setState(() => _missedCallsBadge = (val as int?) ?? 0);
    });

    // Show OEM battery/autostart guide once so the app works on all devices.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      OemBatteryService.showGuideIfNeeded(context);
    });
  }

  @override
  void dispose() {
    _callBadgeSub?.call();
    super.dispose();
  }

  Widget _withBadge(Widget icon, {required int count}) {
    if (count == 0) return icon;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          top: -4,
          right: -4,
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final double navBarHeight = math.min(screenHeight * 0.08, 75.0);
    // Hide bottom nav on home tab (index 0) — tactical home has its own bottom bar
    final bool showNav = curentTabIndex != 0;

    // Restore immersive mode each time the widget rebuilds (e.g. after
    // returning from a pushed route that restored the system UI).
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarContrastEnforced: false,
    ));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && curentTabIndex != 0) {
          setState(() => curentTabIndex = 0);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0E06),
        bottomNavigationBar: showNav
          ? CurvedNavigationBar(
              height: navBarHeight,
              index: curentTabIndex - 1,
              backgroundColor: const Color(0xFF0B0E06), // Matches Scaffold background
              color: const Color(0xFF1B2312), // Or your preferred bar color, leaving as Colors.black if desired, but 0xFF0D1008 is nice

              buttonBackgroundColor: Colors.transparent,
              animationCurve: Curves.easeInOut,
              animationDuration: const Duration(milliseconds: 300),
              onTap: (int index) {
                setState(() {
                  if (index == 2) {
                    // Center button → always go to the tactical home screen
                    curentTabIndex = 0;
                  } else if (index < 2) {
                    curentTabIndex = index + 1;
                  } else {
                    // index > 2 (nav 3→tab4 profile, nav 4→tab5 settings)
                    curentTabIndex = index + 1;
                  }
                  // Reset missed calls badge when navigating to calls tab (index 1 → tab 2)
                  if (index == 1) {
                    GetStorage().write('missed_calls_badge', 0);
                  }
                });
              },
              items: <Widget>[
                BlocBuilder<MessagingBloc, MessagingState>(
                  builder: (context, state) {
                    final total = state.threads.fold<int>(0, (s, t) => s + (t.unRead ?? 0)) +
                        state.groups.fold<int>(0, (s, g) => s + g.unreadCount);
                    return _withBadge(
                      Image.asset("images/Messaging.png", height: 25, width: 25),
                      count: total,
                    );
                  },
                ),
                _withBadge(
                  Image.asset("images/phone_call.png", height: 25, width: 25),
                  count: _missedCallsBadge,
                ),
                const Icon(Icons.home_rounded, color: Colors.white, size: 27),
                Image.asset("images/user.png", height: 25, width: 25),
                Image.asset("images/settings_icon.png", height: 25, width: 25),
              ],
            )
          : null,
        body: Stack(
          children: [
            IndexedStack(
              index: curentTabIndex,
              children: pages,
            ),
            // Top edge — absorbs swipe-down (notification shade)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 44,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onVerticalDragStart: (_) {},
                onVerticalDragUpdate: (_) {},
                onVerticalDragEnd: (_) {},
                onTapDown: (_) {},
                child: const SizedBox.expand(),
              ),
            ),
            // Bottom edge — absorbs swipe-up (back/home/recents gesture bar)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 44,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onVerticalDragStart: (_) {},
                onVerticalDragUpdate: (_) {},
                onVerticalDragEnd: (_) {},
                onTapDown: (_) {},
                child: const SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}