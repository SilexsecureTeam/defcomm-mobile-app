import 'package:defcomm/features/signin/data/models/auth_success_model.dart';
import 'package:defcomm/features/signin/data/models/login_success_model.dart';

import '../models/otp_response_model.dart';

abstract interface class AuthRemoteDataSource {
  Future<OtpResponseModel> requestOtp({
    required String phone,
  });

   Future<LoginSuccessModel> verifyOtp({
    required String phone,
    required String otp,
  });

  Future<void> sendAppConfiguration({required Map<String, dynamic> configData});
}