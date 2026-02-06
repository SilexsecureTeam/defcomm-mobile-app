import 'package:defcomm/core/error/exception.dart';
import 'package:defcomm/core/services/storage_service.dart';
import 'package:defcomm/features/signin/domain/entities/auth_success.dart';
import 'package:defcomm/features/signin/domain/usecases/login_success.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/otp_response.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final StorageService storageService;
  AuthRepositoryImpl(this.remoteDataSource, this.storageService);

  @override
  Future<Either<Failure, OtpResponse>> requestOtp({required String phone}) async {
    try {
      final otpResponse = await remoteDataSource.requestOtp(phone: phone);
      return right(otpResponse);
    } on ServerException catch (e) {
      return left(ServerFailure(e.message));
    }
  }

   @override
  Future<Either<Failure, LoginSuccess>> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    try {
      final loginSuccessModel = await remoteDataSource.verifyOtp(phone: phone, otp: otp);
      
      await storageService.saveString('access_token', loginSuccessModel.accessToken);
      await storageService.saveInt('user_id', loginSuccessModel.user.id);
      await storageService.saveString('user_name', loginSuccessModel.user.name);
      await storageService.saveString('device_id', loginSuccessModel.deviceId);
      
      return right(loginSuccessModel);
    } on ServerException catch (e) {
      return left(ServerFailure(e.message));
    }
  }

   @override
  Future<Either<Failure, void>> sendAppConfiguration(
      Map<String, dynamic> config) async {
    try {
      await remoteDataSource.sendAppConfiguration(configData: config);
      return right(null);
    } on ServerException catch (e) {
      return left(ServerFailure(e.message));
    }
  }
}