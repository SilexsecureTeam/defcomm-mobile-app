import 'package:equatable/equatable.dart';
import 'package:videosdk/videosdk.dart';

abstract class CallState extends Equatable {
  const CallState();

  @override
  List<Object?> get props => [];
}

class CallInitial extends CallState {
  const CallInitial();
}

class CallConnecting extends CallState {
  const CallConnecting();
}

/// The local user has joined the VideoSDK room, but the remote
/// participant hasn't joined yet. The caller sends the invite
/// during this state.
class CallRoomJoined extends CallState {
  final Room room;

  const CallRoomJoined(this.room);

  @override
  List<Object?> get props => [room];
}

class CallConnected extends CallState {

  final Room room;

  const CallConnected(this.room);

  @override
  List<Object?> get props => [room];
}

class CallError extends CallState {
  final String message;

  const CallError(this.message);

  @override
  List<Object?> get props => [message];
}
