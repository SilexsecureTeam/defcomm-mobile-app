import 'dart:async';

class CallManager {
  bool _inProgress = false;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  Stream<bool> get inProgressStream => _controller.stream;

  bool get isCallInProgress => _inProgress;

  
  bool startCall() {
    if (_inProgress) return false;
    _inProgress = true;
    _controller.add(true);
    return true;
  }

  void endCall() {
    if (!_inProgress) return;
    _inProgress = false;
    _controller.add(false);
  }

  void forceClear() {
    _inProgress = false;
    _controller.add(false);
  }

  void dispose() {
    _controller.close();
  }
}
