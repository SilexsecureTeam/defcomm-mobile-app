// lib/core/widgets/call_lifecycle_manager.dart

import 'package:defcomm/core/services/ccallkit_service.dart';
import 'package:defcomm/features/calling/call_control_constants.dart';
import 'package:defcomm/features/calling/presentation/bloc/call_event.dart';
import 'package:defcomm/features/calling/presentation/pages/secure_calling.dart';
import 'package:defcomm/features/chat_details/domain/usecases/send_message.dart';
import 'package:defcomm/init_dependencies.dart';
import 'package:defcomm/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/calling/presentation/bloc/call_bloc.dart';

class CallLifecycleManager extends StatefulWidget {
  final Widget child;
  const CallLifecycleManager({super.key, required this.child});

  @override
  State<CallLifecycleManager> createState() => _CallLifecycleManagerState();
}

class _CallLifecycleManagerState extends State<CallLifecycleManager> {
  @override
  void initState() {
    super.initState();

    CallKitService.init(
      onCallAccepted: (meetingId, callerId, callerName) {
         _navigateToCallScreen(meetingId, callerId, callerName);
      },
      
      onCallEnded: (String callerId) async {
        bool isCallScreenActive = false;
        final nav = navigatorKey.currentState;
        
        if (nav != null) {
          nav.popUntil((route) {
            if (route.settings.name == 'secure_call') {
              isCallScreenActive = true;
            }
            return true; // We are just peeking, not actually popping
          });
        }

        if (isCallScreenActive) {
          return; 
        }
        // 🔹 FIX END


        if (callerId.isNotEmpty && serviceLocator.isRegistered<SendMessage>()) {
          try {
             final sendMessage = serviceLocator<SendMessage>();
             await sendMessage(
               SendMessageParams(
                 message: kCallControlRejected,
                 isFile: false,
                 chatUserType: 'user',
                 currentChatUser: callerId, 
                 chatId: null,
                 mssType: 'call',
               ),
             );
          } catch (e) {
             debugPrint("⚠️ Failed to send rejection: $e");
          }
        }

        try {
          serviceLocator<CallBloc>().add(const CallEnded());
        } catch (_) {}
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      CallKitService.checkAndNavigationForCall(_navigateToCallScreen);
    });
  }

  void _navigateToCallScreen(
    String meetingId,
    String callerId,
    String callerName,
  ) {
    debugPrint(
      "🚀 CallLifecycleManager: Navigating to Call Screen: $meetingId",
    );


    final nav = navigatorKey.currentState;

    if (nav == null) {
      debugPrint("❌ Navigator is null, cannot navigate!");
      return;
    }

    bool isAlreadyInCall = false;
    nav.popUntil((route) {
      if (route.settings.name == 'secure_call') {
        isAlreadyInCall = true;
      }
      return true;
    });

    if (isAlreadyInCall) return;

    nav.push(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'secure_call'),
        builder: (_) => BlocProvider.value(
          value: serviceLocator<CallBloc>(),
          child: SecureCallingScreen(
            isCaller: false,
            meetingId: meetingId,
            otherUserName: callerName,
            peerIdEn: callerId,
            shouldAutoJoin:
                true, 
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
