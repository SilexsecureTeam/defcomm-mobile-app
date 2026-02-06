import 'package:equatable/equatable.dart';

class AuthSuccess extends Equatable {
  final String message; 

  const AuthSuccess({
    required this.message,
  });

  @override
  List<Object?> get props => [message];
}