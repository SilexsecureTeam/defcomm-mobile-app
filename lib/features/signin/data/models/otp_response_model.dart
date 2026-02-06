import '../../domain/entities/otp_response.dart';

class OtpResponseModel extends OtpResponse {
  const OtpResponseModel({
    required super.status,
    required super.message
  });

  factory OtpResponseModel.fromJson(Map<String, dynamic> map) {
    return OtpResponseModel(
      status: map['status'] as int,
      message: map['message'] as String,
    );
  }
}