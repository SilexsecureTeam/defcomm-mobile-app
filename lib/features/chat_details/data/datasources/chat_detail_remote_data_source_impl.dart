// ... imports for http, json, models, exceptions ...

import 'dart:convert';

import 'package:defcomm/core/constants/base_url.dart';
import 'package:defcomm/core/error/exception.dart';
import 'package:defcomm/features/chat_details/data/datasources/chat_detail_remote_data_source.dart';
import 'package:defcomm/features/chat_details/data/models/chat_messge_model.dart';
import 'package:defcomm/features/chat_details/data/models/chat_page_model.dart';
import 'package:defcomm/features/chat_details/data/models/send_message_response.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class ChatDetailRemoteDataSourceImpl implements ChatDetailRemoteDataSource {
  final http.Client client;
  ChatDetailRemoteDataSourceImpl(this.client);

  final box = GetStorage();

  @override
  Future<ChatPageModel> fetchMessages({
    required String chatUserId,
    required int page,
  }) async {
    try {
      final token = box.read("accessToken");

      final response = await client.get(
        Uri.parse('$baseUrl/user/chat/messages/$chatUserId/user?page=$page'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint("chat response: ${response.body}");
      debugPrint("chat statuscode: ${response.statusCode}");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ChatPageModel.fromJson(jsonDecode(response.body));
      } else {
        throw ServerException('Failed to load messages.');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<ChatMessageModel> sendMessage({
    required String message,
    required bool isFile,
    required String chatUserType,
    required String currentChatUser,
    String? chatId,

    required String mssType,
    String? tagMessageId,
    String? tagMessageText,
    List<String>? tagUserIds,
  }) async {
    final token = box.read("accessToken");
    try {
      final url = Uri.parse('$baseUrl/user/chat/messages/send');
      // Create a Multipart request
      final request = http.MultipartRequest('POST', url);

      request.headers['Authorization'] = 'Bearer $token';

      // 🔹 Base fields
      request.fields['mss_type'] = mssType;
      request.fields['message'] = message;
      request.fields['is_file'] = isFile ? 'yes' : 'no';
      request.fields['current_chat_user_type'] = chatUserType;
      request.fields['current_chat_user'] = currentChatUser;

      if (chatId != null && chatId.isNotEmpty) {
        request.fields['chat_id'] = chatId;
      }

      // 🔹 mss_type: text / call / video / ...
      request.fields['mss_type'] = mssType;

      // 🔹 Optional tagging
      if (tagMessageId != null && tagMessageId.isNotEmpty) {
        request.fields['tag_mess_id'] = tagMessageId;
      }
      if (tagMessageText != null && tagMessageText.isNotEmpty) {
        request.fields['tag_mess'] = tagMessageText;
      }
      if (tagUserIds != null && tagUserIds.isNotEmpty) {
        // Many backends accept repeated keys tag_user[]
        for (final id in tagUserIds) {
          request.fields['tag_user[]'] = id;
        }
      }

      // If you send a file later, add it here:
      // request.files.add(await http.MultipartFile.fromPath('file_upload', filePath));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final decodedJson = jsonDecode(responseBody);

      debugPrint("send message response: $responseBody");
      debugPrint("send message statuscode: ${response.statusCode}");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final apiResponse = SendMessageResponseModel.fromJson(decodedJson);
        return apiResponse.chatMessage;
      } else {
        throw ServerException(
          decodedJson['error'] ?? 'Failed to send message',
        );
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
