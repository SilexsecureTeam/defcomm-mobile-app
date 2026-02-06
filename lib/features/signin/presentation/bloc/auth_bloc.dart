import 'dart:io';

import 'package:defcomm/features/signin/domain/usecases/send_app_config.dart';
import 'package:defcomm/features/signin/domain/usecases/verify_otp.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/request_otp.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final RequestOtp _requestOtp;
  final VerifyOtp _verifyOtp;
  final SendAppConfig _sendAppConfig;

  AuthBloc({required RequestOtp requestOtp, required VerifyOtp verifyOtp, required SendAppConfig sendAppConfig})
      : _requestOtp = requestOtp, _verifyOtp = verifyOtp, _sendAppConfig = sendAppConfig,
      
        super(AuthInitial()) {
    on<AuthRequestOtp>((event, emit) async {
      emit(AuthLoading());
      final res = await _requestOtp(RequestOtpParams(phone: event.phone));
      
      res.fold(
        (failure) => emit(AuthFailure(failure.message)),
        (otpResponse) => emit(OtpRequestSuccess(otpResponse)),
      );
    });

    // on<AuthVerifyOtp>((event, emit) async {
    //   emit(AuthLoading());
    //   final res = await _verifyOtp(
    //     VerifyOtpParams(phone: event.phone, otp: event.otp),
    //   );
    //   res.fold(
    //     (failure) => emit(AuthFailure(failure.message)),
    //     (success) => emit(AuthVerifySuccess(success)),
    //   );
    // });

    on<AuthVerifyOtp>((event, emit) async {
      emit(AuthLoading());
      
      // 1. Verify OTP
      final res = await _verifyOtp(
        VerifyOtpParams(phone: event.phone, otp: event.otp),
      );

      await res.fold(
        (failure) async => emit(AuthFailure(failure.message)),
        (loginSuccessModel) async {

          
          try {
            final deviceInfo = await _getDevicePayload();
            
            final configRes = await _sendAppConfig(deviceInfo);
            
            configRes.fold(
              (configFailure) {

                emit(AuthFailure("Configuration failed: ${configFailure.message}"));
              },
              (_) {
                emit(AuthVerifySuccess(loginSuccessModel));
              },
            );
          } catch (e) {
             emit(AuthFailure("Device info error: $e"));
          }
        },
      );
    });
  
  }

  Future<Map<String, dynamic>> _getDevicePayload() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    String deviceId = "unknown";
    String deviceType = "unknown";

    if (Platform.isAndroid) {
      deviceType = "android"; 
      AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
     
      deviceId = androidInfo.id; 
    } else if (Platform.isIOS) {
      deviceType = "ios";
      IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
      deviceId = iosInfo.identifierForVendor ?? "unknown_ios_id";
    }

    return {
      "signal_blocking": "on",
      "remote_management": "on",
      "encrypted_storage": "on",
      "self_wipe": "on",
      "imei": deviceId, 
      "device_type": deviceType
    };
  }
}