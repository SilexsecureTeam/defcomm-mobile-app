import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
}

class AuthRequestOtp extends AuthEvent {
  final String phone;
  const AuthRequestOtp({required this.phone});

  @override
  List<Object> get props => [phone];
}

class AuthVerifyOtp extends AuthEvent {
  final String phone;
  final String otp;
  const AuthVerifyOtp({required this.phone, required this.otp});

  @override
  List<Object> get props => [phone, otp];
}