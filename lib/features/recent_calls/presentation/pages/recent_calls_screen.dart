import 'dart:async';
import 'dart:math' as math;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:defcomm/core/di/service_initilaizer.dart';
import 'package:defcomm/core/services/friendly_errors.dart';
import 'package:defcomm/core/theme/app_colors.dart';
import 'package:defcomm/core/utils/call_manager.dart';
import 'package:defcomm/core/utils/call_utils.dart';
import 'package:defcomm/core/utils/format_call_time_stamp.dart';
import 'package:defcomm/features/calling/call_control_constants.dart';
import 'package:defcomm/features/calling/domain/repositories/call_repository.dart';
import 'package:defcomm/features/calling/presentation/bloc/call_bloc.dart';
import 'package:defcomm/features/calling/presentation/pages/secure_calling.dart';
import 'package:defcomm/features/chat_details/domain/usecases/send_message.dart';
import 'package:defcomm/features/home/presentation/widgets/secure_comms_widget.dart';
import 'package:defcomm/features/recent_calls/presentation/cubit/calls_cubit.dart';
import 'package:defcomm/features/recent_calls/presentation/cubit/calls_state.dart';
import 'package:defcomm/features/recent_calls/presentation/model/call_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';


class RecentCallsScreen extends StatefulWidget {
  const RecentCallsScreen({super.key});

  @override
  State<RecentCallsScreen> createState() => _RecentCallsScreenState();
}

class _RecentCallsScreenState extends State<RecentCallsScreen> {
  final box = GetStorage();
  StreamSubscription? _connectivitySubscription;
  late CallsCubit _callsCubit;

  String get myUserId => box.read("userEnId") ?? '';


  @override
    void initState() {
      super.initState();

      _callsCubit = serviceLocator<CallsCubit>()..load();


     _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (!results.contains(ConnectivityResult.none)) {
        debugPrint("🌐 Network restored: Refreshing Call Logs...");
        _callsCubit.load();
      }
    });
    }

     @override
  void dispose() {
    _connectivitySubscription?.cancel();
    // Do NOT close _callsCubit — it is a lazy singleton managed by the
    // service locator. Calling close() permanently kills it and makes
    // recent calls blank on every subsequent tab visit.
    super.dispose();
  }


  void _onCallPressed(
    String userId,
    String otherUserName,
    String peerIdEn,
  ) async {
    final callManager = serviceLocator<CallManager>();

    final acquired = callManager.startCall();
    if (!acquired) {
      Fluttertoast.showToast(msg: 'A call is already in progress');
      debugPrint('Call blocked: another call is in progress');
      return;
    }

    var lockReleased = false;
    void releaseLockIfNeeded() {
      if (!lockReleased) {
        lockReleased = true;
        callManager.endCall();
      }
    }

    final myIdEn = box.read("userEnId") as String;
    final otherIdEn = userId; //widget.user.id;

    final sendMessageUseCase = serviceLocator<SendMessage>();
    final callRepo = serviceLocator<CallRepository>();

    try {
      final String roomId = await callRepo.createMeetingId();
      debugPrint("✅ VideoSDK Room Ready (Recent Calls): $roomId");

      await sendMessageUseCase(
        SendMessageParams(
          message: '$kCallControlInvitePrefix$roomId',
          isFile: false,
          chatUserType: 'user',
          currentChatUser: otherIdEn,
          chatId: null,
          mssType: 'call',
        ),
      );

      Navigator.of(context)
          .push(
            MaterialPageRoute(
              settings: const RouteSettings(name: 'secure_call'),
              builder: (_) => BlocProvider.value(
                value: serviceLocator<CallBloc>(),
                child: SecureCallingScreen(
                  isCaller: true,
                  meetingId: roomId,
                  otherUserName: otherUserName,
                  peerIdEn: peerIdEn, //widget.user.id,
                ),
              ),
            ),
          )
          .then((_) {
            releaseLockIfNeeded();
          });

    } catch (e) {
      debugPrint('Error sending call signal: $e');
      releaseLockIfNeeded();
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final double navBarHeight = (screenHeight * 0.08).clamp(0.0, 75.0);

    final String name = box.read("name") ?? "You";
    final String role = box.read("role");

    return BlocProvider.value(
      value: _callsCubit,
      // create: (_) => serviceLocator<CallsCubit>()..load(),
      child: Scaffold(
        backgroundColor: AppColors.tertiaryGreen,

        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.dashboardBackgroundColor,
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 36, left: 16.0, right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildCustomAppBar(context, name, role),
                    const SizedBox(height: 24),
                    const SecureCommsWidget(
                      activeIconUrl: "images/phone_call.png",
                      showAllButton: false,
                      showNameText: false,
                      showBar: true,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Recent Calls',
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Expanded(
                      child: BlocBuilder<CallsCubit, CallsState>(
                        builder: (context, state) {
                          if (state.isLoading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                           if (state.error != null) {
                            if (state.calls.isEmpty) {
                               Fluttertoast.showToast(msg: "Error fetching calls");
                               return _buildErrorView(state.error ?? "");
                            }
                            debugPrint("Sync error: ${state.error}");
                          }

                          final calls = state.calls;

                          if (calls.isEmpty) {
                            return Center(
                              child: Text(
                                '',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: calls.length,
                            itemBuilder: (context, index) {
                              final call = calls[index];

                              final isSenderCurrent =
                                  call.sendUserId == myUserId;
                              final displayName = isSenderCurrent
                                  ? (call.receiveUserName?.isNotEmpty == true
                                        ? call.receiveUserName!
                                        : (call.receiveUserPhone ?? 'Unknown'))
                                  : (call.sendUserName.isNotEmpty
                                        ? call.sendUserName
                                        : call.sendUserPhone);

                              final bool isMissed = () {
                                final s = call.callState.toLowerCase();
                                return s.contains('miss') ||
                                    s.contains('reject') ||
                                    s.contains('no_answer') ||
                                    s.contains('declined');
                              }();
                              final Color nameColor = (!isSenderCurrent && isMissed)
                                  ? const Color(0xFFE53935)
                                  : Colors.white;

                              return InkWell(
                                onTap: () {
                                  final remoteId = isSenderCurrent
                                      ? call.receiveUserId
                                      : call.sendUserId;
                                  if (remoteId != null &&
                                      remoteId.isNotEmpty) {
                                    _onCallPressed(
                                      remoteId,
                                      displayName,
                                      isSenderCurrent
                                          ? call.receiveUserId
                                          : call.sendUserId,
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      // Avatar
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundImage: const AssetImage(
                                          "images/profile_img.png",
                                        ),
                                      ),
                                      const SizedBox(width: 14),

                                      // Name + full date below
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              displayName,
                                              style: GoogleFonts.poppins(
                                                color: nameColor,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              formatCallFullDate(
                                                  call.createdAtUtc),
                                              style: GoogleFonts.poppins(
                                                color: Colors.white54,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Call type icon
                                      _buildCallTypeIcon(
                                        isSenderCurrent: isSenderCurrent,
                                        callState: call.callState,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallTypeIcon({
    required bool isSenderCurrent,
    required String callState,
  }) {
    final String state = callState.toLowerCase();
    final bool isMissed = state.contains('miss') ||
        state.contains('reject') ||
        state.contains('no_answer') ||
        state.contains('declined');

    final String asset = isSenderCurrent
        ? 'images/outgoing_call.png'
        : (isMissed ? 'images/missed_call.png' : 'images/incoming_call.png');

    return Image.asset(asset, width: 16, height: 16);
  }

  Widget buildCustomAppBar(BuildContext context, name, role) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Row(
      children: [
        const Icon(Icons.apps_rounded, color: Colors.white, size: 28),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w400,
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
        Container(
          height: screenHeight * 0.05,
          width: screenHeight * 0.05,
          decoration: BoxDecoration(
            color: AppColors.tertiaryGreen,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: IconButton(
              icon: const Icon(
                Icons.add,
                color: AppColors.primaryWhite,
                size: 15,
              ),
              onPressed: () {},
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
              Icons.wifi_off_rounded, 
              size: 60,
              color: Colors.white24,
            ),
            const SizedBox(height: 16),

            // 2. Title
            Text(
              "oops!",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // 3. Description
            Text(
              friendlyMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // 4. Retry Button
            SizedBox(
              width: 140,
              height: 45,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32), // Your App Green
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  debugPrint("reload cal logs");
                  // context.read<CallsCubit>().load();

                  BlocProvider<CallsCubit>(
      // create a cubit for this screen and start loading immediately
      create: (_) => serviceLocator<CallsCubit>()..load(),
      
                  );
                //     GroupMessagesFetched(groupUserIdEn),
                //   );
                },
                // onPressed: () {
                //   // TRIGGER THE LOAD EVENT AGAIN
                //   // Assuming your event is named GetChatMessages or similar
                //   // You need to pass the conversation ID or User again
                //   
                //   context.read<GroupMembersBloc>().add(
                //     FetchGroupMembers(groupUserIdEn),
                //   );

                //   if (serviceLocator.isRegistered<PusherService>()) {
                //     serviceLocator<PusherService>().setActiveChat(
                //       groupUserIdEn,
                //     );
                //   }
                // },
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
