import 'dart:async';
import 'dart:math' as math;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:defcomm/core/pusher/pusher_service.dart';
import 'package:defcomm/core/services/friendly_errors.dart';
import 'package:defcomm/core/theme/app_colors.dart';
import 'package:defcomm/features/chat_details/data/models/chat_user_model.dart';
import 'package:defcomm/features/groups/presentation/bloc/group_member_bloc.dart';
import 'package:defcomm/features/groups/presentation/pages/group_members_screen.dart';
import 'package:defcomm/features/groups/presentation/pages/group_page.dart';
import 'package:defcomm/features/home/presentation/widgets/secure_comms_widget.dart';
import 'package:defcomm/features/messaging/presentation/bloc/messaging_bloc.dart';
import 'package:defcomm/features/messaging/presentation/bloc/messaging_event.dart';
import 'package:defcomm/features/messaging/presentation/bloc/messaging_state.dart';
import 'package:defcomm/features/messaging/presentation/model/message_thread.dart';
import 'package:defcomm/features/messaging/presentation/model/story_contact.dart';
import 'package:defcomm/features/messaging/presentation/widgets/group_tile.dart';
import 'package:defcomm/features/messaging/presentation/widgets/message_thread_tile.dart';
import 'package:defcomm/features/messaging/presentation/widgets/stories_list.dart';
import 'package:defcomm/init_dependencies.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:defcomm/features/groups/domain/entities/group_entity.dart';
import 'package:defcomm/features/groups/presentation/bloc/group_bloc.dart';
import 'package:defcomm/features/groups/presentation/bloc/group_event.dart';
import 'package:defcomm/features/groups/presentation/bloc/group_state.dart';

class MessagingScreen extends StatefulWidget {
  const MessagingScreen({super.key});

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  bool _threadsExpanded = true;
  bool _groupsExpanded = true;

  StreamSubscription? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<MessagingBloc>();

    // bloc.add(FetchStoriesEvent());
    // bloc.add(FetchMessageThreadsEvent());
    // bloc.add(FetchGroupEvent());

    bloc.add(FetchStoriesEvent());
    bloc.add(FetchMessageThreadsEvent());
    bloc.add(FetchGroupEvent());

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (!results.contains(ConnectivityResult.none)) {
        debugPrint("Network restored in Group Chat: Syncing...");

        context.read<MessagingBloc>().add(FetchStoriesEvent());
        context.read<MessagingBloc>().add(FetchMessageThreadsEvent());
        context.read<MessagingBloc>().add(FetchGroupEvent());

        if (serviceLocator.isRegistered<PusherService>()) {
          serviceLocator<PusherService>().reconnect();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double navBarHeight = math.min(screenHeight * 0.08, 75.0);
    final box = GetStorage();
    String name = box.read("name") ?? "You";
    String role = box.read("role") ?? "user";
    return Scaffold(
      backgroundColor: AppColors.tertiaryGreen,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.dashboardBackgroundColor,
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16),
                  child: _buildCustomAppBar(context, name, role),
                ),

                // SPACING
                const SizedBox(height: 10),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    children: [
                      Text(
                        'SECURE MESSAGING',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // const SecureCommsWidget(
                      //   activeIconUrl: "images/Messaging.png",
                      //   showAllButton: false,
                      //   showNameText: false,
                      //   showBar: true,
                      // ),
                      const SizedBox(height: 15),

                      // STORIES
                      BlocBuilder<MessagingBloc, MessagingState>(
                        buildWhen: (previous, current) {
                          return !listEquals(
                                previous.stories,
                                current.stories,
                              ) ||
                              previous.storiesLoading !=
                                  current.storiesLoading ||
                              previous.storiesError != current.storiesError;
                        },
                        builder: (context, state) {
                          // if ( // state.storiesLoading &&
                          // state.stories.isEmpty) {
                          //   return const Center(
                          //     child: Text(
                          //       "Loading chats...",
                          //       style: TextStyle(color: Colors.white),
                          //     ),
                          //   );
                          // }

                          if (state.stories.isNotEmpty) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                StoriesList(stories: state.stories),
                              ],
                            );
                          }

                          if (state.storiesError != null &&
                              state.stories.isEmpty) {
                            return _buildErrorView(state.storiesError ?? "");
                          }

                          // 3. Show Empty state
                          // if (state.stories.isEmpty) {
                          //   return const Center(
                          //     child: Text(
                          //       "No chats yet.",
                          //       style: TextStyle(color: Colors.white70),
                          //     ),
                          //   );
                          // }

                          return const Center(
                            child: Text(
                              "",// "No chats yet.",
                              style: TextStyle(color: Colors.white70),
                            ),
                          );

                          // return StoriesList(stories: state.stories);
                        },
                      ),

                      const SizedBox(height: 32),

                      GestureDetector(
                        onTap: () => setState(
                          () => _threadsExpanded = !_threadsExpanded,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Chats',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),

                            AnimatedRotation(
                              turns: _threadsExpanded
                                  ? 0.5
                                  : 0.0, 
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                Icons.expand_more, 
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      BlocBuilder<MessagingBloc, MessagingState>(
                       
                        builder: (context, state) {
                          

                          if (state.threadsError != null &&
                              state.threads.isEmpty) {
                            return Center(
                              child: Text(
                                state.threadsError!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            );
                          }

                          if (state.threads.isEmpty) {
                            return const Center(
                              child: Text(
                                "No chats yet.",
                                style: TextStyle(color: Colors.white70),
                              ),
                            );
                          }

                          debugPrint(
                            "UI REBUILDING. Thread[0] isTyping: ${state.threads.isNotEmpty ? state.threads[0].isTyping : 'empty'}",
                          );
                          final listView = ListView.builder(
                            shrinkWrap: true,
                            physics:
                                const NeverScrollableScrollPhysics(), 
                            itemCount: state.threads.length,
                            itemBuilder: (context, index) {
                              return MessageThreadTile(
                                thread: state.threads[index],
                              );
                            },
                          );

                          return AnimatedCrossFade(
                            firstChild:
                                SizedBox.shrink(), // collapsed state (hidden)
                            secondChild: listView, // expanded state (visible)
                           
                            crossFadeState: _threadsExpanded
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 200),
                            firstCurve: Curves.easeOut,
                            secondCurve: Curves.easeIn,
                            sizeCurve: Curves.easeInOut,
                          );
                        },
                      ),

                      // // // Groups
                      GestureDetector(
                        onTap: () =>
                            setState(() => _groupsExpanded = !_groupsExpanded),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Groups',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),

                            // Animated icon that rotates on toggle
                            AnimatedRotation(
                              turns: _groupsExpanded
                                  ? 0.5
                                  : 0.0, 
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                Icons.expand_more, 
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12),

                      BlocBuilder<MessagingBloc, MessagingState>(
                        buildWhen: (previous, current) {
                          return !listEquals(previous.groups, current.groups) ||
                              previous.groupsLoading != current.groupsLoading ||
                              previous.groupError != current.groupError;
                        },
                        builder: (context, state) {
                       

                          // 2. Show error only if we have NO data
                          if (state.groupError != null &&
                              state.groups.isEmpty) {
                            return _buildErrorView(state.groupError ?? "");
                          }

                          // 3. Show Empty state
                          if (state.groups.isEmpty) {
                            return const Center(
                              child: Text(
                                "No groups yet.",
                                style: TextStyle(color: Colors.white70),
                              ),
                            );
                          }

                          final listView = ListView.builder(
                            shrinkWrap: true,
                            physics:
                                const NeverScrollableScrollPhysics(), 
                            itemBuilder: (context, index) {
                              return GroupTile(group: state.groups[index]);
                            },
                          );

                          return AnimatedCrossFade(
                            firstChild:
                                SizedBox.shrink(),
                                secondChild: listView,
                            crossFadeState: _groupsExpanded
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 200),
                            firstCurve: Curves.easeOut,
                            secondCurve: Curves.easeIn,
                            sizeCurve: Curves.easeInOut,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context, String name, String role) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    void _navigateToGroupsPage() {
      // Get the existing bloc from the current context
      final groupBloc = context.read<GroupBloc>();

      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false, 
          pageBuilder: (ctx, animation, secondaryAnimation) {
            return BlocProvider.value(
              value: groupBloc, 
              child: const GroupsPage(),
            );
          },
          transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }

    return Row(
      children: [
        const CircleAvatar(
          radius: 18,
          backgroundImage: AssetImage('images/profile_img.png'),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: screenWidth * 0.5,
              child: Text(
                name,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                overflow: TextOverflow.fade,
              ),
            ),
            Text(
              role,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const Spacer(),
        GestureDetector(
          onTap: _navigateToGroupsPage,
          child: Container(
            height: screenHeight * 0.05,
            width: screenHeight * 0.05,
            decoration: BoxDecoration(
              color: AppColors.tertiaryGreen,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: IconButton(
                icon: const Icon(
                  Icons.add,
                  color: AppColors.primaryWhite,
                  size: 15,
                ),
                onPressed: null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView(String rawError) {
    final friendlyMessage = getUserFriendlyError(rawError);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. Icon
            Icon(
              Icons.wifi_off_rounded, //  Icons.error_outline
              size: 60,
              color: Colors.white24,
            ),
            const SizedBox(height: 16),

            Text(
              "oops!",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              friendlyMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: 140,
              height: 45,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32), 
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  
                  final bloc = context.read<MessagingBloc>();
                  bloc.add(FetchStoriesEvent());
                  bloc.add(FetchMessageThreadsEvent());
                  bloc.add(FetchGroupEvent());
                },
                child: Text(
                  "Retry",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
