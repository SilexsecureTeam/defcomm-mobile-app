import '../../domain/entities/auth_success.dart';

class AuthSuccessModel extends AuthSuccess {
  const AuthSuccessModel({required super.message});

  factory AuthSuccessModel.fromJson(Map<String, dynamic> map) {
    return AuthSuccessModel(
      message: map['message'] as String,
    );
  }
}