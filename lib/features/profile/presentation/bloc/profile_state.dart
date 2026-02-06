// profile_state.dart
import 'package:equatable/equatable.dart';

class ProfileState extends Equatable {
  final bool isOnline;

  const ProfileState({
    this.isOnline = true, 
  });

  ProfileState copyWith({
    bool? isOnline,
  }) {
    return ProfileState(
      isOnline: isOnline ?? this.isOnline,
    );
  }

  @override
  List<Object> get props => [isOnline];
}