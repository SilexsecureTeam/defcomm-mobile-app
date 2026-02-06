import 'dart:convert';
import 'package:defcomm/core/constants/base_url.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import '../models/qr_session_model.dart';

abstract class QrRemoteDataSource {
  Future<QrSessionModel> getStatus(String qrId);
  Future<void> approve(String qrId);
}

class QrRemoteDataSourceImpl implements QrRemoteDataSource {
  final http.Client client;
  final box = GetStorage();

  QrRemoteDataSourceImpl({required this.client});

  @override
  Future<QrSessionModel> getStatus(String qrId) async {
    final token = box.read("accessToken");
    final res = await client.get(
      Uri.parse('$baseUrl/qr/$qrId/status'),
      headers: {'Authorization': 'Bearer $token'},
    );
    debugPrint("getStatus uri:  ${Uri.parse('$baseUrl/qr/$qrId/status')}");

    debugPrint("getStatus: response: ${res.body}");

    if (res.statusCode != 200) {
      throw Exception('Failed to fetch QR status');
    }

    final json = jsonDecode(res.body);
    return QrSessionModel.fromJson(json, qrId);
  }

  @override
  Future<void> approve(String qrId) async {
    final token = box.read("accessToken");
    final res = await client.post(
      Uri.parse('$baseUrl/qr/$qrId/approve'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'confirm': true}),
    );

    debugPrint("getStatus uri:  ${Uri.parse('$baseUrl/qr/$qrId/status')}");

    debugPrint("approve response: ${res.body}");

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Failed to approve QR');
    }
  }
}
