import 'dart:async';
import 'package:defcomm/core/constants/base_url.dart';
import 'package:defcomm/core/di/service_initilaizer.dart';
import 'package:defcomm/core/theme/app_colors.dart';
import 'package:defcomm/core/utils/call_manager.dart';
import 'package:defcomm/features/calling/call_control_constants.dart';
import 'package:defcomm/features/calling/presentation/bloc/call_bloc.dart';
import 'package:defcomm/features/calling/presentation/bloc/call_event.dart';
import 'package:defcomm/features/calling/presentation/bloc/call_state.dart';
import 'package:defcomm/features/chat_details/domain/usecases/send_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:get_storage/get_storage.dart';
import 'package:videosdk/videosdk.dart';

class SecureCallingScreen extends StatefulWidget {
  final bool isCaller;

  final String? meetingId;

  final String otherUserName;

  final String peerIdEn;

  final bool shouldAutoJoin;

  const SecureCallingScreen({
    super.key,
    required this.isCaller,
    this.meetingId,
    required this.otherUserName,

    required this.peerIdEn,

    this.shouldAutoJoin = false,
  });

  @override
  State<SecureCallingScreen> createState() => _SecureCallingScreenState();
}

class _SecureCallingScreenState extends State<SecureCallingScreen> {
  final _box = GetStorage();

  bool _inviteSent = false;

  bool _isMuted = false;
  bool _isSpeakerOn = false;

  /// For showing "0:23" / "1:05" etc if you want later
  Timer? _durationTimer;
  int _elapsedSeconds = 0;

  Room? _connectedRoom;
  bool _remoteJoined = false;
  Function? _onParticipantJoinedCallback;

  bool _hasCallStarted = false;

  bool _isAutoJoining = false;
  bool _isDialingTonePlaying = false;

  @override
  void initState() {
    super.initState();

    // start VideoSDK via BLoC
    // final callBloc = context.read<CallBloc>();
    _isAutoJoining = widget.shouldAutoJoin;

    final myDisplayName = _box.read('userName') ?? 'You';

    // callBloc.add(
    //   StartCallRequested(
    //     // token: videoDevTokenKey,          // constant dev token (not used in repo but required by event)
    //     meetingId: widget.isCaller
    //         ? null                        // create new meeting
    //         : widget.meetingId,           // join existing
    //     displayName: myDisplayName,       // your own name as participant
    //     micEnabled: true,
    //     camEnabled: true,
    //   ),
    // );
  
    // ── Defensive reset: the CallBloc is a singleton and may retain
    // stale state from a previous call that wasn't cleaned up. ──
    final bloc = context.read<CallBloc>();
    if (bloc.state is! CallInitial) {
      debugPrint('⚠️ CallBloc was in stale state ${bloc.state}, resetting…');
      bloc.add(const CallEnded());
      // Give the bloc one frame to process the reset before continuing
      // Note: initState cannot be async, so we can't await here directly.
      // The reset will happen, but the subsequent call logic might run
      // before the bloc fully transitions to CallInitial.
      // For this specific case, it's generally safe as the next event
      // (StartCallRequested) will override any intermediate state.
    }

    if (widget.isCaller) {
      context.read<CallBloc>().add(
        StartCallRequested(
          meetingId: widget.meetingId,
          displayName: myDisplayName,
          micEnabled: true,
          camEnabled: true,
        ),
      );
    } else if (widget.shouldAutoJoin) {
      // Small delay to ensure widget is ready
      Future.delayed(Duration.zero, () {
        _performCallAcceptance();
      });
    }
  }

  Future<void> _performCallAcceptance() async {
    debugPrint("✅ Auto-accepting call...");
    FlutterRingtonePlayer().stop();

    // A. Send the Signal
    // Note: We create a helper for sending control text to reuse it
    await _sendCallControlMessage(kCallControlAccepted);

    // B. Join the VideoSDK Room
    final myDisplayName = _box.read('userName') ?? 'You';

    // if (!mounted) return;

    context.read<CallBloc>().add(
      StartCallRequested(
        meetingId: widget.meetingId,
        displayName: myDisplayName,
        micEnabled: true,
        camEnabled: true,
      ),
    );
  }

  @override
  void dispose() {
    FlutterRingtonePlayer().stop();
    _durationTimer?.cancel();

    try {
      if (_connectedRoom != null) {
        debugPrint("Leaving room via Dispose Safety Net");
        _connectedRoom!.leave();
        _connectedRoom = null;
      }
    } catch (e) {
      debugPrint('Error leaving room in dispose: $e');
    }

    // ── Safety net: always reset the singleton CallBloc so the next
    // call screen starts clean. ──
    try {
      serviceLocator<CallBloc>().add(const CallEnded());
    } catch (e) {
      debugPrint('Error resetting CallBloc in dispose: $e');
    }

    super.dispose();
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _elapsedSeconds = 0;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(1, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _sendCallControlMessage(String controlText) async {
    try {
      final sendMessage = serviceLocator<SendMessage>();

      await sendMessage(
        SendMessageParams(
          message: controlText,
          isFile: false,
          chatUserType: 'user',
          currentChatUser: widget.peerIdEn,
          chatId: null,
          mssType: 'call',
        ),
      );
      debugPrint("control txt: ${controlText}");
    } catch (e) {
      debugPrint('Failed to send call control message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: AppColors.appGradientColor2),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: BlocConsumer<CallBloc, CallState>(
              listener: (context, state) async {
                // ── Mark call as started for any active state ──
                if (state is CallConnecting ||
                    state is CallRoomJoined ||
                    state is CallConnected) {
                  if (_isAutoJoining) {
                    setState(() {
                      _isAutoJoining = false;
                    });
                  }
                  _hasCallStarted = true;
                }

                // ── Remote end hung up → close this screen ──
                if (state is CallInitial && _hasCallStarted) {
                  if (mounted) {
                    debugPrint("Call ended remotely, closing screen.");
                    Navigator.of(context).maybePop();
                  }
                  return;
                }

                // ── Room joined (local) — send invite & play dial tone ──
                if (state is CallRoomJoined) {
                  final room = state.room;
                  _connectedRoom = room;

                  // Caller: play dialing tone while waiting for callee
                  // Caller: play dialing tone while waiting for callee
                  if (widget.isCaller && !_isDialingTonePlaying) {
                    _isDialingTonePlaying = true;
                    debugPrint("Started Dialing Tone...");
                    FlutterRingtonePlayer().play(
                      fromAsset: "audio/phone-calling-tone.mp3",
                      ios: IosSounds.glass,
                      looping: true,
                      volume: 0.7,
                    );
                  }

                  // Invite was already sent by chat_screen/recent_calls_screen
                  // before navigating here, so we only need to track it.
                  _inviteSent = true;
                }

                // ── Remote participant joined → call is live ──
                if (state is CallConnected) {
                  final room = state.room;
                  _connectedRoom = room;

                  // Stop dialing / ringing tone
                  if (_isDialingTonePlaying) {
                    _isDialingTonePlaying = false;
                    FlutterRingtonePlayer().stop();
                    debugPrint("Peer joined, stopped dialing tone.");
                  }

                  if (!_remoteJoined) {
                    _remoteJoined = true;
                    _startDurationTimer();
                  }
                }

                // ── Error ──
                if (state is CallError) {
                  if (_isDialingTonePlaying) {
                    _isDialingTonePlaying = false;
                    FlutterRingtonePlayer().stop();
                  }
                  _stopDurationTimer();
                  _remoteJoined = false;
                  _connectedRoom = null;
                }
              },
              builder: (context, state) {
                final bool isConnecting =
                    (state is CallConnecting) ||
                    (state is CallRoomJoined) ||
                    _isAutoJoining;
                final bool isConnected = state is CallConnected;
                final String timerText = isConnected
                    ? _formatDuration(_elapsedSeconds)
                    : '0:00';

                return Column(
                  children: [
                    _buildTopBanner(timerText),
                    const SizedBox(height: 24),
                    _buildContactInfo(context),

                    const Spacer(),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: isConnecting
                          ? _buildConnectingView()
                          : isConnected
                          ? _buildConnectedView(state)
                          : _buildErrorOrIdle(state),
                    ),

                    const Spacer(),

                    _buildLogo(context),
                    const SizedBox(height: 20),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: widget.isCaller && isConnected
                          ? _buildEndCallButton(context)
                          : _buildReceiverBottom(
                              state,
                              context,
                              widget.meetingId.toString(),
                              widget.isCaller,
                              (controlText) =>
                                  _sendCallControlMessage(controlText),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- UI pieces (almost same as your original) ----------------

  Widget _buildTopBanner(String timerText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.settingAccountGreen,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset("images/secure_call_icon_1.png"),
              const SizedBox(width: 12),
              Text(
                "Secure Calling...",
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                timerText, // dynamic timer instead of "0.00"
                style: GoogleFonts.poppins(
                  color: AppColors.tertiaryGreen,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 12),
              Image.asset("images/secure_call_icon_2.png"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Row(
      children: [
        CircleAvatar(
          radius: screenWidth * 0.06,
          backgroundColor: AppColors.otpFieldUnFocusBorder,
          child: Center(
            child: Image.asset(
              "images/military_helmet.png",
              height: screenHeight * 0.08,
              width: screenWidth * 0.07,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          widget.otherUserName,
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildConnectingView() {
    return Column(
      key: const ValueKey('connecting'),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.tertiaryGreen,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset("images/network_service.png"),
              const SizedBox(width: 8),
              Text(
                "Checking call...",
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(
            strokeWidth: 6,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF91C83E)),
            backgroundColor: Colors.white.withOpacity(0.2),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "initiating End to end Encryption",
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }

  // Widget _buildConnectedView() {
  //   return Container(
  //     key: const ValueKey('connected'),
  //     constraints: const BoxConstraints(maxWidth: 170, maxHeight: 170),
  //     child: GridView.count(
  //       shrinkWrap: true,
  //       physics: const NeverScrollableScrollPhysics(),
  //       crossAxisCount: 2,
  //       crossAxisSpacing: 5,
  //       mainAxisSpacing: 5,
  //       children: [
  //         _buildActionButton(
  //           url: "images/phone.png",
  //           text: "Receiver",
  //           color: AppColors.primaryWhite,
  //           textColor: AppColors.tertiaryGreen,
  //           tL: 20,
  //           tR: 0,
  //           bL: 0,
  //           bR: 0,
  //         ),
  //         _buildActionButton(
  //           url: "images/speaker.png",
  //           text: "Speaker",
  //           tL: 0,
  //           tR: 20,
  //           bL: 0,
  //           bR: 0,
  //         ),
  //         _buildActionButton(
  //           url: "images/mute.png",
  //           text: "Mute",
  //           tL: 0,
  //           tR: 0,
  //           bL: 20,
  //           bR: 0,
  //         ),
  //         _buildActionButton(
  //           url: "images/new_call.png",
  //           text: "New Call",
  //           tL: 0,
  //           tR: 0,
  //           bL: 0,
  //           bR: 20,
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // --- Replace your existing _buildConnectedView() with this ---
  Widget _buildConnectedView(CallState state) {
    // Get the Room instance if available
    final Room? room = (state is CallConnected) ? state.room : null;

    return Container(
      key: const ValueKey('connected'),
      constraints: const BoxConstraints(maxWidth: 170, maxHeight: 170),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
        children: [
          // Receiver (unchanged visual)
          _buildActionButton(
            url: "images/phone.png",
            text: "Receiver",
            color: AppColors.primaryWhite,
            textColor: AppColors.tertiaryGreen,
            imgColor: null,
            tL: 5,
            tR: 0,
            bL: 0,
            bR: 0,
          ),

          // Speaker - tappable
          GestureDetector(
            onTap: () async {
              if (room == null) {
                Fluttertoast.showToast(msg: 'Not connected to room yet');
                return;
              }
              await _toggleSpeaker(room);
            },
            child: _buildActionButton(
              url: "images/speaker.png",
              text: _isSpeakerOn ? "Speaker" : "Speaker",
              // change colors when active
              color: _isSpeakerOn ? AppColors.primaryWhite : null,
              textColor: _isSpeakerOn ? AppColors.tertiaryGreen : null,
              imgColor: _isSpeakerOn ? AppColors.tertiaryGreen : null,
              tL: 0,
              tR: 5,
              bL: 0,
              bR: 0,
            ),
          ),

          // Mute - tappable
          GestureDetector(
            onTap: () async {
              if (room == null) {
                Fluttertoast.showToast(msg: 'Not connected to room yet');
                return;
              }
              await _toggleMute(room);
            },
            child: _buildActionButton(
              url: "images/mute.png",
              text: _isMuted ? "Muted" : "Mute",
              // change colors when active
              color: _isMuted ? AppColors.primaryWhite : null,
              textColor: _isMuted ? AppColors.tertiaryGreen : null,
              imgColor: _isMuted ? AppColors.tertiaryGreen : null,

              tL: 0,
              tR: 0,
              bL: 5,
              bR: 0,
            ),
          ),

          // New Call (unchanged)
          _buildActionButton(
            url: "images/new_call.png",
            text: "New Call",
            tL: 0,
            tR: 0,
            bL: 0,
            bR: 5,
            color: null,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorOrIdle(CallState state) {
    if (state is CallError) {
      return Column(
        key: const ValueKey('error'),
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(height: 8),
          Text('Call failed', style: GoogleFonts.poppins(color: Colors.white)),
          const SizedBox(height: 4),
          Text(
            state.message,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
    // If somehow idle here
    return const SizedBox(key: ValueKey('idle'));
  }

  Widget _buildActionButton({
    required String url,
    required String text,
    Color? color,
    Color? textColor,
    Color? imgColor,
    required double tL,
    required double tR,
    required double bL,
    required double bR,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? AppColors.tertiaryGreen,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(tL),
          topRight: Radius.circular(tR),
          bottomLeft: Radius.circular(bL),
          bottomRight: Radius.circular(bR),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(url, height: 20, width: 20, color: imgColor),
          const SizedBox(height: 8),
          Text(
            text,
            style: GoogleFonts.poppins(color: textColor ?? Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(left: screenWidth * 0.12),
          child: Text(
            "Secured by",
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
          ),
        ),
        Image.asset('images/defcomm_calling_logo.png', height: 30),
      ],
    );
  }

  Widget _buildEndCallButton(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () {
        // FlutterRingtonePlayer().stop();

        // context.read<CallBloc>().add(CallEnded());

        _endLocalCallAndNotifyPeer(context);
        // Navigator.pop(context);
      },
      child: Container(
        width: screenWidth * 0.5,
        height: screenHeight * 0.07,
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            "End the call",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCallerBottom(CallState state, BuildContext context) {
    final isConnected = state is CallConnected;
    return _buildRedEndButton(
      context,
      label: isConnected ? "End call" : "Cancel call",
      onTap: () {
        FlutterRingtonePlayer().stop();
        context.read<CallBloc>().add(const CallEnded());
        Navigator.pop(context);
      },
    );
  }

  /// Receiver sees Accept/Reject first; after joining, same End button.
  Widget _buildReceiverBottom(
    CallState state,
    BuildContext context,
    String meetingId,
    bool isCaller,
    Future<void> Function(String) sendControlText,
  ) {
    final bool isConnecting = state is CallConnecting || state is CallRoomJoined;
    final bool isConnected = state is CallConnected;

    // 1) BEFORE accepting: initial incoming call
    if (state is CallInitial && !_isAutoJoining) {
      return Row(
        key: const ValueKey('incoming_buttons'),
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // ❌ Reject
          _buildCircleButton(
            color: Colors.red,
            icon: Icons.call_end,
            label: "Reject",
            onTap: () async {
              FlutterRingtonePlayer().stop();

              final controlText = isCaller
                  ? kCallControlEnded
                  : kCallControlRejected;
              await sendControlText(controlText);

              context.read<CallBloc>().add(const CallEnded());
              Navigator.of(context).pop();
            },
          ),

          // ✅ Accept
          _buildCircleButton(
            color: AppColors.tertiaryGreen,
            icon: Icons.call,
            label: "Accept",
            onTap: () {
              _performCallAcceptance();
            },
            // () async {
            //   FlutterRingtonePlayer().stop();

            //   // 1. Tell caller that callee accepted
            //   await sendControlText(kCallControlAccepted);

            //   // 2. Join the VideoSDK room
            //   final myDisplayName = GetStorage().read('userName') ?? 'You';

            //   context.read<CallBloc>().add(
            //     StartCallRequested(
            //       // token: videoDevTokenKey, // 👈 required
            //       meetingId: meetingId, // roomId from Pusher
            //       displayName: myDisplayName,
            //       micEnabled: true,
            //       camEnabled: true,
            //     ),
            //   );
            // },
          ),
        ],
      );
    }

    // 2) While joining after Accept, but before remote join
    if (isConnecting && !isConnected) {
      return _buildRedEndButton(
        context,
        label: "Cancel",
        onTap: () {
          FlutterRingtonePlayer().stop();
          context.read<CallBloc>().add(const CallEnded());
          Navigator.pop(context);
        },
      );
    }

    // 3) Once connected → normal End call
    if (isConnected) {
      return _buildRedEndButton(
        context,
        label: "End off call",
        onTap: () {
          _endLocalCallAndNotifyPeer(context);

          // FlutterRingtonePlayer().stop();
          // context.read<CallBloc>().add(const CallEnded());
          // Navigator.pop(context);
        },
      );
    }

    // fallback – keep height to avoid jump
    return const SizedBox(key: ValueKey('receiver_empty'), height: 60);
  }

  Widget _buildRedEndButton(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      key: ValueKey(label),
      onTap: onTap,
      child: Container(
        width: screenWidth * 0.5,
        height: screenHeight * 0.07,
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required Color color,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: CircleAvatar(
            radius: 30,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }

  // --- helper: toggle mute ---
  Future<void> _toggleMute(Room room) async {
    try {
      if (!_isMuted) {
        // mute
        // VideoSDK Room exposes muteMic() / unmuteMic()
        await room.muteMic();
        setState(() => _isMuted = true);
        Fluttertoast.showToast(msg: 'Microphone muted');
      } else {
        // unmute
        await room.unmuteMic();
        setState(() => _isMuted = false);
        Fluttertoast.showToast(msg: 'Microphone unmuted');
      }
    } catch (e) {
      debugPrint('toggleMute error: $e');
      Fluttertoast.showToast(msg: 'Could not toggle mute');
    }
  }

  // --- helper: toggle speaker (attempt using VideoSDK device APIs) ---
  Future<void> _toggleSpeaker(Room room) async {
    try {
      // optimistic toggle locally first so UI feels snappy
      final newValue = !_isSpeakerOn;
      // Try to find audio devices and switch via VideoSDK if available
      try {
        // VideoSDK.getAudioDevices() may be on VideoSDK class or Room depending on version.
        // We'll attempt the most common: VideoSDK.getAudioDevices()
        final audioDevices = await VideoSDK.getAudioDevices();
        if (audioDevices != null && audioDevices.isNotEmpty) {
          // prefer labels containing "speaker" or "earpiece"/"receiver"
          AudioDeviceInfo? speakerDevice;
          AudioDeviceInfo? receiverDevice;

          for (final d in audioDevices) {
            final label = (d.label ?? '').toString().toLowerCase();
            if (label.contains('speaker')) speakerDevice = d;
            if (label.contains('receiver') ||
                label.contains('earpiece') ||
                label.contains('phone')) {
              receiverDevice = d;
            }
          }

          if (newValue && speakerDevice != null) {
            await room.switchAudioDevice(speakerDevice);
          } else if (!newValue && receiverDevice != null) {
            await room.switchAudioDevice(receiverDevice);
          } else if (newValue && speakerDevice == null) {
            // fallback: pick the last device or the one with kind 'speaker' if present
            await room.switchAudioDevice(audioDevices.last);
          } else if (!newValue && receiverDevice == null) {
            await room.switchAudioDevice(audioDevices.first);
          }
        } else {
          // if getAudioDevices not available or empty, try room.switchAudioDevice with no args (some versions)
          if (newValue) {
            // Some SDKs provide setDefaultAudioRouteToSpeaker or similar; try switch to speaker via an API
            // if no such method, we'll rely on platform defaults
            // (We intentionally do nothing here if not available)
          }
        }
      } catch (inner) {
        // If VideoSDK device APIs are not available in this version, we can consider using
        // flutter_audio_output as a fallback (see note below).
        debugPrint('audio device switch attempt failed: $inner');
      }

      setState(() => _isSpeakerOn = newValue);
      Fluttertoast.showToast(msg: _isSpeakerOn ? 'Speaker on' : 'Speaker off');
    } catch (e) {
      debugPrint('toggleSpeaker error: $e');
      Fluttertoast.showToast(msg: 'Could not toggle speaker');
    }
  }

  // void _endLocalCallAndNotifyPeer(BuildContext context) async {
  //   try {
  //     // 1) Send control message so the remote side will close too
  //     await _sendCallControlMessage(kCallControlEnded);

  //     try {
  //       //  serviceLocator<CallBloc>().add(const CallEnded());
  //       context.read<CallBloc>().add(const CallEnded());
  //       serviceLocator<CallManager>().endCall();
  //     } catch (e) {
  //       debugPrint('Could not add CallEnded to CallBloc: $e');
  //     }

  //     FlutterRingtonePlayer().stop();
  //     _stopDurationTimer();

  //     // 4) Close the UI (pop)
  //     if (mounted) {
  //       Navigator.of(context).maybePop();
  //       // Navigator.of(context).pop();
  //     }
  //   } catch (e) {
  //     debugPrint('Error ending call locally: $e');
  //   }
  // }

  void _endLocalCallAndNotifyPeer(BuildContext context) async {
    // 1. Close locally FIRST — never block on the network call.
    FlutterRingtonePlayer().stop();
    _stopDurationTimer();

    if (mounted) {
      context.read<CallBloc>().add(const CallEnded());
      Navigator.of(context).maybePop();
    }

    try {
      serviceLocator<CallManager>().endCall();
    } catch (_) {}

    // 2. Fire-and-forget the control message so the remote side also closes.
    _sendCallControlMessage(kCallControlEnded).catchError((e) {
      debugPrint('Failed to send end-call signal: $e');
    });
  }
}
