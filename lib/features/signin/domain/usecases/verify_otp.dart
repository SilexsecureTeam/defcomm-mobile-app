import 'package:defcomm/features/signin/domain/usecases/login_success.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/auth_success.dart';
import '../repositories/auth_repository.dart';

class VerifyOtp implements UseCase<LoginSuccess, VerifyOtpParams> {
  final AuthRepository authRepository;
  VerifyOtp(this.authRepository);

  @override
  Future<Either<Failure, LoginSuccess>> call(VerifyOtpParams params) async {
    return await authRepository.verifyOtp(phone: params.phone, otp: params.otp);
  }
}

class VerifyOtpParams {
  final String phone;
  final String otp;
  VerifyOtpParams({required this.phone, required this.otp});
}