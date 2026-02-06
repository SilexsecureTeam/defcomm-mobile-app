import 'dart:convert';

import 'package:defcomm/core/constants/base_url.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import '../models/call_model.dart';

abstract class CallsRemoteDataSource {
  Future<List<CallModel>> fetchRecentCalls();
}

class CallsRemoteDataSourceImpl implements CallsRemoteDataSource {
  final http.Client client;

  CallsRemoteDataSourceImpl({required this.client});

  final box = GetStorage();

  @override
  Future<List<CallModel>> fetchRecentCalls() async {
    final token = box.read("accessToken");
    final res = await client.get(Uri.parse('$baseUrl/user/chat/callLog'), headers:  {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      });

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    final dynamic jsonBody = json.decode(res.body);
    if (jsonBody is! Map<String, dynamic>) {
      throw Exception('Unexpected JSON format from API.');
    }

    final data = jsonBody['data'];
    if (data == null) return <CallModel>[];

    if (data is! List) {
      throw Exception('Expected "data" to be an array.');
    }

    final models = data
        .where((e) => e is Map<String, dynamic>)
        .map((e) => CallModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return models;
  }
}
