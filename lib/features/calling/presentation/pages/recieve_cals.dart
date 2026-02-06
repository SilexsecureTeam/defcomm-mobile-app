import 'package:defcomm/core/utils/call_manager.dart';
import 'package:defcomm/features/calling/presentation/bloc/call_bloc.dart';
import 'package:defcomm/features/calling/presentation/bloc/call_event.dart';
import 'package:defcomm/init_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

class RecieveCals extends StatefulWidget {
  const RecieveCals({super.key});

  @override
  State<RecieveCals> createState() => _RecieveCalsState();
}

class _RecieveCalsState extends State<RecieveCals> {

  void _endLocalCallAndNotifyPeer(BuildContext context) async {
    try {
      // 1. Send control message so the remote side will close too
      // await _sendCallControlMessage(kCallControlEnded);

      // 2. Notify the Bloc via CONTEXT (Not ServiceLocator)
      // We use context.read because we need the specific instance
      // attached to this widget tree that holds the active _room.
      if (mounted) {
        context.read<CallBloc>().add(const CallEnded());
      }

      // 3. Release global lock
      serviceLocator<CallManager>().endCall();

      // 4. Stop Ringtone and Timers
      FlutterRingtonePlayer().stop();
      // _stopDurationTimer();

      // 5. Close the UI
      // if (mounted) {
      //   Navigator.of(context).maybePop();
      // }
    } catch (e) {
      debugPrint('Error ending call locally: $e');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      body: Center(
        child: TextButton(
          onPressed: () {
            _endLocalCallAndNotifyPeer(context);
            Navigator.pop(context);
          },
          child: const Text(
            "Go Back",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
      )
    );
  }
}