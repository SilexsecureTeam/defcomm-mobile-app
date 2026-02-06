import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart'; // We will create this
import '../entities/otp_response.dart';
import '../repositories/auth_repository.dart';

class RequestOtp implements UseCase<OtpResponse, RequestOtpParams> {
  final AuthRepository authRepository;
  RequestOtp(this.authRepository);

  @override
  Future<Either<Failure, OtpResponse>> call(RequestOtpParams params) async {
    return await authRepository.requestOtp(phone: params.phone);
  }
}

class RequestOtpParams {
  final String phone;
  RequestOtpParams({required this.phone});
}