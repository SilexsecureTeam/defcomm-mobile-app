import 'dart:convert';
import 'package:defcomm/core/constants/base_url.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

abstract class CallRemoteDataSource {
  Future<String> createMeeting();
}

class CallRemoteDataSourceImpl implements CallRemoteDataSource {
  final http.Client client;
  static const String _baseUrl = 'https://api.videosdk.live/v2';

  CallRemoteDataSourceImpl({required this.client});

  @override
  Future<String> createMeeting() async {
    final uri = Uri.parse('$_baseUrl/rooms');

    final response = await client.post(
      uri,
      headers: {
        'Authorization': videoDevTokenKey,       // e.g. "Bearer YOUR_DEV_TOKEN"
        'Content-Type': 'application/json',
      },
    );

    debugPrint('VideoSDK createMeeting status: ${response.statusCode}');
    debugPrint('VideoSDK createMeeting body: ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final jsonMap = json.decode(response.body) as Map<String, dynamic>;
      final roomId = jsonMap['roomId'] as String?;
      if (roomId == null || roomId.isEmpty) {
        throw Exception('VideoSDK response missing roomId');
      }
      return roomId;
    } else {
      throw Exception(
        'Failed to create meeting. Status: ${response.statusCode}',
      );
    }
  }
}
