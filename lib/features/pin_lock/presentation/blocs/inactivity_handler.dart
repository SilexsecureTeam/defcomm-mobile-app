import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_app_lock/flutter_app_lock.dart';

class InactivityHandler extends StatefulWidget {
  final Widget child;
  const InactivityHandler({required this.child, Key? key}) : super(key: key);

  @override
  _InactivityHandlerState createState() => _InactivityHandlerState();
}

class _InactivityHandlerState extends State<InactivityHandler> {
  Timer? _inactivityTimer;

  void _resetTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(Duration(minutes: 3), () {
      AppLock.of(context)!.lock();
    });
  }

  @override
  void initState() {
    super.initState();
    _resetTimer();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _resetTimer(),
      child: widget.child,
    );
  }
}

extension on AppLockState {
  void lock() {}
}

