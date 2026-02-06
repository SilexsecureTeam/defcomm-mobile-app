import 'package:equatable/equatable.dart';

class OtpResponse extends Equatable {
  final int status;
  final String message;

  const OtpResponse({
    required this.status,
    required this.message,
  });

  @override
  List<Object?> get props => [status, message];
}