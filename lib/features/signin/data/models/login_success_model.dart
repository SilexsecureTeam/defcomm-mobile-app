import 'package:defcomm/features/signin/domain/usecases/login_success.dart';
import 'user_model.dart';

class LoginSuccessModel extends LoginSuccess {
  const LoginSuccessModel({
    required super.accessToken,
    required super.userEnid,
    required super.user,
    required super.deviceId,
  });

  factory LoginSuccessModel.fromJson(Map<String, dynamic> map) {
    final data = map['data'] as Map<String, dynamic>;
    
    return LoginSuccessModel(
      accessToken: data['access_token'] as String,
      userEnid: data['user_enid'] as String,
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
      deviceId: data['device_id'] as String,
    );
  }
}