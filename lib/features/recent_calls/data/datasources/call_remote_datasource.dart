import 'dart:convert';

import 'package:defcomm/core/constants/base_url.dart';
import 'package:flutter/foundation.dart';
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
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    // Run both endpoints in parallel for speed.
    final results = await Future.wait([
      _fetchCallLog(headers),
      _fetchNotifications(headers),
    ]);

    final callLogModels    = results[0];
    final notifModels      = results[1];

    // Merge & deduplicate by ID — call log takes priority.
    final seen = <String>{};
    final merged = <CallModel>[];
    for (final m in [...callLogModels, ...notifModels]) {
      if (seen.add(m.id)) merged.add(m);
    }

    debugPrint('📞 fetchRecentCalls: callLog=${callLogModels.length}  notifications=${notifModels.length}  merged=${merged.length}');
    return merged;
  }

  Future<List<CallModel>> _fetchCallLog(Map<String, String> headers) async {
    try {
      final res = await client.get(
        Uri.parse('$baseUrl/user/chat/callLog'),
        headers: headers,
      );
      debugPrint('📞 /callLog status: ${res.statusCode}');
      debugPrint('📞 /callLog body: ${res.body.substring(0, res.body.length.clamp(0, 300))}');
      if (res.statusCode < 200 || res.statusCode >= 300) return [];
      return _parseCallList(res.body, isNotification: false);
    } catch (e) {
      debugPrint('📞 /callLog error: $e');
      return [];
    }
  }

  Future<List<CallModel>> _fetchNotifications(Map<String, String> headers) async {
    try {
      final res = await client.get(
        Uri.parse('$baseUrl/user/notification'),
        headers: headers,
      );
      debugPrint('🔔 /notification status: ${res.statusCode}');
      debugPrint('🔔 /notification body: ${res.body.substring(0, res.body.length.clamp(0, 300))}');
      if (res.statusCode < 200 || res.statusCode >= 300) return [];
      return _parseCallList(res.body, isNotification: true);
    } catch (e) {
      debugPrint('🔔 /notification error: $e');
      return [];
    }
  }

  List<CallModel> _parseCallList(String body, {required bool isNotification}) {
    try {
      final dynamic jsonBody = json.decode(body);
      if (jsonBody is! Map<String, dynamic>) return [];

      dynamic raw = jsonBody['data'];
      // Unwrap nested pagination: { "data": { "data": [...] } }
      if (raw is Map && raw.containsKey('data')) raw = raw['data'];
      if (raw == null || raw is! List) return [];

      if (isNotification) {
        return raw
            .where((e) => e is Map)
            .map((e) => CallModel.fromNotification(
                  Map<String, dynamic>.from(e as Map),
                ))
            .whereType<CallModel>()
            .toList();
      } else {
        return raw
            .where((e) => e is Map<String, dynamic>)
            .map((e) => CallModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('_parseCallList error: $e');
      return [];
    }
  }
}
