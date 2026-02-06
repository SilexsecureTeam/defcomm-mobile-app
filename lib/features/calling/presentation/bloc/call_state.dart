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
