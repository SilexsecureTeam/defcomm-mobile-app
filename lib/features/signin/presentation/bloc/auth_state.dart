import 'package:defcomm/features/signin/domain/entities/auth_success.dart';
import 'package:defcomm/features/signin/domain/usecases/login_success.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/otp_response.dart';

abstract class AuthState extends Equatable {
  const AuthState();
}

class AuthInitial extends AuthState {
  @override
  List<Object> get props => [];
}

class AuthLoading extends AuthState {
  @override
  List<Object> get props => [];
}

class AuthFailure extends AuthState {
  final String message;
  const AuthFailure(this.message);

  @override
  List<Object> get props => [message];
}

class OtpRequestSuccess extends AuthState {
  final OtpResponse otpResponse;
  const OtpRequestSuccess(this.otpResponse);

  @override
  List<Object> get props => [otpResponse];
}

class AuthVerifySuccess extends AuthState {
  final LoginSuccess authSuccess;
  const AuthVerifySuccess(this.authSuccess);

  @override
  List<Object> get props => [authSuccess];
}