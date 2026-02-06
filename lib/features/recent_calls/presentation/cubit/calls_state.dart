import 'package:equatable/equatable.dart';
import '../../domain/entities/call_entity.dart';

class CallsState extends Equatable {
  final bool isLoading;
  final List<CallEntity> calls;
  final String? error;

  const CallsState({required this.isLoading, required this.calls, this.error});

  factory CallsState.initial() => const CallsState(isLoading: false, calls: [], error: null);

  CallsState copyWith({bool? isLoading, List<CallEntity>? calls, String? error}) {
    return CallsState(
      isLoading: isLoading ?? this.isLoading,
      calls: calls ?? this.calls,
      error: error,
    );
  }

  @override
  List<Object?> get props => [isLoading, calls, error];
}
