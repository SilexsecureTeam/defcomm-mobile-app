import 'dart:async';
import 'dart:convert';
import 'package:defcomm/core/constants/base_url.dart'; // Ensure token/constants are here
import 'package:defcomm/core/di/service_initilaizer.dart';
import 'package:defcomm/core/theme/app_colors.dart';
import 'package:defcomm/core/utils/call_manager.dart';
import 'package:defcomm/core/utils/call_utils.dart';
import 'package:defcomm/features/calling/call_control_constants.dart';
// Import your new Cubit
import 'package:defcomm/features/calling/presentation/bloc/call_cubit.dart'; 
import 'package:defcomm/features/chat_details/domain/usecases/send_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get_storage/get_storage.dart';
import 'package:videosdk/videosdk.dart';

// Assuming this utility exists based on your previous code context
// If not, you must import the file where `buildSingleCallRoomId` is defined.
// import 'package:defcomm/core/utils/room_id_utils.dart'; 

class SecureCallingScreen1 extends StatefulWidget {
  final bool isCaller;
  final String? meetingId;
  final String otherUserName;
  final String peerIdEn;

  const SecureCallingScreen1({
    super.key,
    required this.isCaller,
    this.meetingId,
    required this.otherUserName,
    required this.peerIdEn,
  });

  @override
  State<SecureCallingScreen1> createState() => _SecureCallingScreen1State();
}

class _SecureCallingScreen1State extends State<SecureCallingScreen1> {
  final _box = GetStorage();
  
  // Flags
  bool _inviteSent = false;
  bool _isSpeakerOn = false;
  bool _remoteJoined = false;

  // Timer
  Timer? _durationTimer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _initializeMeeting();
  }

  void _initializeMeeting() {
  final myIdEn = _box.read("userEnId") ?? "unknown_user";
  // Get the saved name or default to 'You'
  final myDisplayName = _box.read('userName') ?? 'You';

  String roomId = "";

  // 1. Determine Room ID
  if (widget.meetingId != null && widget.meetingId!.isNotEmpty) {
    roomId = widget.meetingId!;
    debugPrint("✅ Using provided meetingId: $roomId");
  } else {
    // 2. Generate ID if Caller
    // Make sure neither ID is empty before generating
    if (myIdEn.isNotEmpty && widget.peerIdEn.isNotEmpty) {
      roomId = buildSingleCallRoomId(myIdEn, widget.peerIdEn);
      debugPrint("✅ Generated deterministic roomId: $roomId");
    } else {
      debugPrint("❌ ERROR: Cannot generate roomId. MyID: $myIdEn, PeerID: ${widget.peerIdEn}");
      Fluttertoast.showToast(msg: "Call Error: Invalid User IDs");
      Navigator.pop(context); // Close screen if we can't generate ID
      return;
    }
  }

  // 3. Final Check
  if (roomId.isEmpty) {
    debugPrint("❌ CRITICAL: Room ID is empty after generation logic.");
    Fluttertoast.showToast(msg: "Call Error: Room ID Missing");
    Navigator.pop(context);
    return;
  }

  // 4. Initialize via Cubit (Pass displayName now)
   String token = videoDevTokenKey; // Ensure this is not empty!
  
  if (token.isEmpty) {
     debugPrint("❌ CRITICAL: VideoSDK Token is empty.");
     return;
  }

  context.read<MeetingCubit>().initializeRoom(
    token, 
    roomId, 
    // myDisplayName, 
    context
  );
}

  @override
  void dispose() {
    FlutterRingtonePlayer().stop();
    _stopDurationTimer();

    try {
     context.read<MeetingCubit>().leaveMeeting();
  } catch (e) {
     debugPrint("Cubit already closed or not found");
  }
    super.dispose();
  }

  // --- Timer Logic ---
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

  // --- Pusher Signaling ---
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
          mssType: 'text', // Usually 'text' for control messages so they parse correctly
        ),
      );
      debugPrint("Call Control Sent: $controlText");
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
            child: BlocConsumer<MeetingCubit, MeetingState>(
              listener: (context, state) async {
                final cubit = context.read<MeetingCubit>();
                
                // 1. Check connection status (Simplest way: do we have a local participant?)
                final isConnected = state.participants.containsKey(cubit.room.localParticipant.id);

                if (isConnected) {
                  // --- Handle Remote Join ---
                  // If there is more than 1 participant, the other person joined
                  if (state.participants.length > 1 && !_remoteJoined) {
                    _remoteJoined = true;
                    _startDurationTimer();
                    FlutterRingtonePlayer().stop(); // Stop ringing if we were playing it
                  }

                  // --- Handle Sending Invite (Caller Only) ---
                  if (widget.isCaller && !_inviteSent) {
                    _inviteSent = true;
                    final roomId = cubit.room.id;
                    final controlText = '$kCallControlInvitePrefix$roomId';
                    await _sendCallControlMessage(controlText);
                  }
                }
                
                // Note: The Cubit handles navigation.pop in 'roomLeft' event
                // inside _setMeetingEventListener, so we don't strictly need to pop here.
              },
              builder: (context, state) {
                final cubit = context.read<MeetingCubit>();
                
                // Determine connection state for UI
                // Note: cubit.room might throw if accessed before init, 
                // but we init in initState. To be safe, try/catch or check initialization.
                bool isConnected = false;
                try {
                   isConnected = state.participants.containsKey(cubit.room.localParticipant.id);
                } catch (_) {}

                final String timerText = _remoteJoined 
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
                      child: !isConnected
                          ? _buildConnectingView()
                          : _buildConnectedView(state, cubit),
                    ),

                    const Spacer(),

                    _buildLogo(context),
                    const SizedBox(height: 20),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: widget.isCaller && isConnected
                          ? _buildEndCallButton(context, cubit)
                          : _buildReceiverBottom(
                              context,
                              cubit,
                              state,
                              isConnected,
                              (controlText) => _sendCallControlMessage(controlText),
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

  // ---------------- UI Widgets ----------------

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
                timerText,
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
    return Row(
      children: [
        CircleAvatar(
          radius: screenWidth * 0.06,
          backgroundColor: AppColors.otpFieldUnFocusBorder,
          child: Center(
            child: Image.asset(
              "images/military_helmet.png",
              height: 40, width: 40,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          widget.otherUserName,
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 16,
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
                "Establishing Connection...",
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
          "Initiating End-to-End Encryption",
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildConnectedView(MeetingState state, MeetingCubit cubit) {
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
          // 1. Receiver
          _buildActionButton(
            url: "images/phone.png",
            text: "Receiver",
            color: AppColors.primaryWhite,
            textColor: AppColors.tertiaryGreen,
            tL: 20, tR: 0, bL: 0, bR: 0,
          ),

          // 2. Speaker (Local Logic)
          GestureDetector(
            onTap: () => _toggleSpeaker(cubit.room),
            child: _buildActionButton(
              url: "images/speaker.png",
              text: _isSpeakerOn ? "Speaker On" : "Speaker",
              color: _isSpeakerOn ? AppColors.primaryWhite : null,
              textColor: _isSpeakerOn ? AppColors.tertiaryGreen : null,
              imgColor: _isSpeakerOn ? AppColors.tertiaryGreen : null,
              tL: 0, tR: 20, bL: 0, bR: 0,
            ),
          ),

          // 3. Mute (Cubit Logic)
          GestureDetector(
            onTap: () {
              cubit.toggleMic();
              Fluttertoast.showToast(msg: state.isMicOff ? "Unmuted" : "Muted");
            },
            child: _buildActionButton(
              url: "images/mute.png",
              text: state.isMicOff ? "Muted" : "Mute",
              color: state.isMicOff ? AppColors.primaryWhite : null,
              textColor: state.isMicOff ? AppColors.tertiaryGreen : null,
              imgColor: state.isMicOff ? AppColors.tertiaryGreen : null,
              tL: 0, tR: 0, bL: 20, bR: 0,
            ),
          ),

          // 4. New Call
          _buildActionButton(
            url: "images/new_call.png",
            text: "New Call",
            tL: 0, tR: 0, bL: 0, bR: 20,
            color: null,
          ),
        ],
      ),
    );
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

  // --- End / Reject Buttons ---

  Widget _buildEndCallButton(BuildContext context, MeetingCubit cubit) {
    return _buildRedButton(
      context,
      label: "End the call",
      onTap: () => _endLocalCallAndNotifyPeer(context, cubit),
    );
  }

  Widget _buildReceiverBottom(
    BuildContext context,
    MeetingCubit cubit,
    MeetingState state,
    bool isConnected,
    Future<void> Function(String) sendControlText,
  ) {
    // 1. Initial State (Waiting for Accept/Reject)
    // Since 'isConnected' logic relies on room join, if we haven't joined yet,
    // we are in the "Incoming Call" state.
    if (!isConnected) {
       // However, we initiate join immediately in initState in this logic.
       // NOTE: If you want to wait for "Accept" press before joining VideoSDK, 
       // you need to change logic. Assuming your logic is: 
       // User clicks Notification -> Screen opens -> Auto Join? 
       // Or Screen opens -> User sees Accept/Reject -> Clicks Accept -> Join.
       
       // Based on the code structure provided, initState calls initializeRoom immediately.
       // If you want "Accept/Reject", we must NOT call initializeRoom in initState if (!isCaller).
    }
    
    // ADJUSTMENT: We will handle logic assuming we are *Connected* or *Connecting*
    // but visually, if we are NOT the caller, and just opened the screen,
    // we usually want to see "Accept/Reject". 
    
    // Since initState calls join immediately, let's treat "End Call" as the main action.
    // If you explicitly want Accept/Reject buttons *before* joining video, 
    // you need to modify initState to wait.
    
    if (isConnected) {
      return _buildRedButton(
        context,
        label: "End Call",
        onTap: () => _endLocalCallAndNotifyPeer(context, cubit),
      );
    } 

    // If connecting...
    return _buildRedButton(
      context,
      label: "Cancel",
      onTap: () {
        _endLocalCallAndNotifyPeer(context, cubit);
      },
    );
  }

  Widget _buildRedButton(BuildContext context, {required String label, required VoidCallback onTap}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return GestureDetector(
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

  // --- Logic Helpers ---

  Future<void> _toggleSpeaker(Room room) async {
    try {
      final newValue = !_isSpeakerOn;
      final audioDevices = await VideoSDK.getAudioDevices();
      
      if (audioDevices!.isNotEmpty) {
        AudioDeviceInfo? targetDevice;
        for (final d in audioDevices) {
          final label = d.label.toString().toLowerCase();
          if (newValue && label.contains('speaker')) {
            targetDevice = d;
            break;
          } else if (!newValue && (label.contains('receiver') || label.contains('earpiece'))) {
            targetDevice = d;
            break;
          }
        }
        targetDevice ??= audioDevices.first; // Fallback
        await room.switchAudioDevice(targetDevice);
      }
      setState(() => _isSpeakerOn = newValue);
      Fluttertoast.showToast(msg: _isSpeakerOn ? 'Speaker On' : 'Speaker Off');
    } catch (e) {
      debugPrint("Speaker toggle error: $e");
    }
  }

  void _endLocalCallAndNotifyPeer(BuildContext context, MeetingCubit cubit) async {
    FlutterRingtonePlayer().stop();
    _stopDurationTimer();

    try {
      // 1. Send End Control Message
      // If we are rejecting (didn't join fully) or ending active call
      final statusMsg = (!widget.isCaller && !_remoteJoined && _elapsedSeconds == 0) 
          ? kCallControlRejected 
          : kCallControlEnded;
          
      await _sendCallControlMessage(statusMsg);

      // 2. Leave VideoSDK Room
      cubit.leaveMeeting(); // This emits roomLeft which pops the screen
      
      // 3. Clear global lock
      serviceLocator<CallManager>().endCall();

      // Note: Cubit's _setMeetingEventListener listens to Events.roomLeft 
      // and calls Navigator.pop. So we don't strictly need to pop here manually
      // if leaveMeeting() succeeds. 
    } catch (e) {
      debugPrint("Error ending call: $e");
      Navigator.of(context).maybePop();
    }
  }
}