import 'package:equatable/equatable.dart';

import 'user.dart';

class LoginSuccess extends Equatable {
  final String accessToken;
  final String userEnid;
  final User user;
  final String deviceId;

  const LoginSuccess({
    required this.accessToken,
    required this.userEnid,
    required this.user,
    required this.deviceId,
  });

  @override
  List<Object?> get props => [accessToken, userEnid, user, deviceId];
}