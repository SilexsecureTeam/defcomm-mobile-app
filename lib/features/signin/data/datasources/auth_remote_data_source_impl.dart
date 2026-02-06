import 'dart:convert';
import 'package:defcomm/core/constants/base_url.dart';
import 'package:defcomm/core/di/service_initilaizer.dart';
import 'package:defcomm/core/error/exception.dart';
import 'package:defcomm/features/signin/data/models/auth_success_model.dart';
import 'package:defcomm/features/signin/data/models/login_success_model.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import '../models/otp_response_model.dart';
import 'auth_remote_data_source.dart';

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client client;
  AuthRemoteDataSourceImpl(this.client);
  final box = GetStorage();

  @override
  Future<OtpResponseModel> requestOtp({required String phone}) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/requestOtpSms'), 
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      );

      final resBody = jsonDecode(response.body);
      debugPrint("response statuscode: ${response.statusCode}");
      debugPrint("response body: ${response.body}");
      box.write("phone", phone);

      if (response.statusCode == 200) {
        

        return OtpResponseModel.fromJson(resBody);
      } else {

         final serverMessage = resBody['message'] ??
          resBody['error'] ??
          (resBody['errors'] is String ? resBody['errors'] : null) ??
          (resBody['errors'] is Map ? jsonEncode(resBody['errors']) : null) ??
          response.body;

        throw ServerException(serverMessage);
      }
    } on ServerException{
      rethrow;
    }
    
    catch (e, st) {
      throw ServerException(e.toString());
    }
  }


   @override
  Future<LoginSuccessModel> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/loginWithPhone'), 
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'otp': otp,
        }),
      );
      debugPrint("login response statuscode: ${response.statusCode}");
      debugPrint("login response body: ${response.body}");

      final resBody = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final loginDetails = LoginSuccessModel.fromJson(resBody);
        box.write("accessToken", loginDetails.accessToken);
        box.write("name", loginDetails.user.name);
        box.write("phone", loginDetails.user.phone);
        box.write("email", loginDetails.user.email);
        box.write("userEnId", loginDetails.userEnid);
        box.write("role", resBody['data']['user']['role']);
        debugPrint("resBody['data']['user']['role']:   ${resBody['data']['user']['role']}");
      

        await startPusherForUser(token: loginDetails.accessToken, userId: loginDetails.userEnid);

        return LoginSuccessModel.fromJson(resBody);
      } else {
        final serverMessage = resBody['message'] ??
          resBody['error'] ??
          (resBody['errors'] is String ? resBody['errors'] : null) ??
          (resBody['errors'] is Map ? jsonEncode(resBody['errors']) : null) ??
          response.body;

      throw ServerException(serverMessage);
      }
    } on ServerException {
      
    rethrow;
  } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> sendAppConfiguration({required Map<String, dynamic> configData}) async {
    final token = box.read("accessToken"); 
    
    try {
      final url = Uri.parse('$baseUrl/app/configuration'); 
      
      final response = await client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(configData),
      );

      debugPrint("Config Config Response: ${response.statusCode}");
      debugPrint("Config Config Body: ${response.body}");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return; 
      } else {
        final resBody = jsonDecode(response.body);
        throw ServerException(resBody['message'] ?? "Failed to set configuration");
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}