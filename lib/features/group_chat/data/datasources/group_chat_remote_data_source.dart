import 'dart:convert';
import 'package:defcomm/core/constants/base_url.dart';
import 'package:defcomm/core/error/exception.dart';
import 'package:defcomm/features/group_chat/data/models/group_chat_message_model.dart';
import 'package:defcomm/features/group_chat/domain/usecases/send_group_message.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

import '../models/group_chat_page_model.dart';

abstract class GroupChatRemoteDataSource {
  Future<GroupChatPageModel> getGroupMessages({
    required String groupUserIdEn,
    required int page,
  });

  Future<GroupChatMessageModel> sendGroupMessage(SendGroupMessageParams params);
}

class GroupChatRemoteDataSourceImpl implements GroupChatRemoteDataSource {
  final http.Client client;

  GroupChatRemoteDataSourceImpl({required this.client});

  final box = GetStorage();

  @override
  Future<GroupChatPageModel> getGroupMessages({
    required String groupUserIdEn,
    required int page,
  }) async {
    final token = box.read("accessToken");
    final uri = Uri.parse(
      '$baseUrl/user/chat/messages/$groupUserIdEn/group?page=$page',
    );

    final response = await client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    debugPrint('GroupChat GET ${uri.toString()}');
    debugPrint('status: ${response.statusCode}');
    debugPrint('body: ${response.body}');
    print('body: ${response.body}');

    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      // 👇 IMPORTANT: compare as String, or use toString()
      final apiStatus = body['status']?.toString();

      if (apiStatus == '200') {
        return GroupChatPageModel.fromJson(body);
      } else {
        // real API-level error
        throw ServerException(body['message'] ?? 'Unknown server response');
      }
    } else {
      // HTTP-level error
      throw ServerException(
        'Server error: ${response.statusCode} - ${body['message'] ?? 'Something went wrong'}',
      );
    }
  }

  @override
  Future<GroupChatMessageModel> sendGroupMessage(
    SendGroupMessageParams params,
  ) async {
    final token = box.read('accessToken');

    final uri = Uri.parse('$baseUrl/user/chat/messages/send');

    final bodyMap = <String, dynamic>{
      'message': params.message,
      'is_file': params.isFile ? 'yes' : 'no',
      'current_chat_user_type': 'group',
      'current_chat_user': params.currentChatUser, 
      'mss_type': params.mssType,
      'tag_user': params.tagUserIds, // array
      if (params.tagMessageId != null) 'tag_mess': params.tagMessageId,
    };

    debugPrint('Send group message $uri');
    debugPrint('payload: ${jsonEncode(bodyMap)}');

    final response = await client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(bodyMap),
    );

    debugPrint('status: ${response.statusCode}');
    debugPrint('body: ${response.body}');

    final decoded = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final map = jsonDecode(response.body) as Map<String, dynamic>;
      // depending on backend:
      final data =
          (map['data'] ?? map['mss_chat'] ?? map) as Map<String, dynamic>;
      final m = decoded['data']?['data'] as Map<String, dynamic>;
      return GroupChatMessageModel.fromJson(m);
    } else {
      throw ServerException(
        decoded['message']?.toString() ?? 'Failed to send group message',
      );
    }
  }
}
