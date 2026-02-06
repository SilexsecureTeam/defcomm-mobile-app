import 'dart:convert';
import 'dart:io';

import 'package:defcomm/core/constants/base_url.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class SecurityReporter {
  SecurityReporter();

  Future<bool> report({required String screen}) async {
    final box = GetStorage();

    final token = box.read('accessToken');
    final userId = box.read('userEnId');

     if (token == null || userId == null) return false;
     debugPrint("sending report");
     Fluttertoast.showToast(msg:"sending report");

    final response = await http.post(
      Uri.parse('$baseUrl/security/screenshot-attempt'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${box.read("accessToken")}',
      },
      body: jsonEncode({
        'user_id': userId,
        'screen': screen,
        'platform': Platform.operatingSystem,
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );

    return response.statusCode >= 200 && response.statusCode < 300;

  }
}
