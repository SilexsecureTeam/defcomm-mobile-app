import 'package:defcomm/features/signin/domain/usecases/login_success.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart'; 
import '../entities/otp_response.dart';

abstract interface class AuthRepository {
  Future<Either<Failure, OtpResponse>> requestOtp({
    required String phone,
  });

  Future<Either<Failure, LoginSuccess>> verifyOtp({
    required String phone,
    required String otp,
  });

  Future<Either<Failure, void>> sendAppConfiguration(Map<String, dynamic> config);
}