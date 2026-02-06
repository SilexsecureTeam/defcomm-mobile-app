import 'dart:convert';
import 'package:defcomm/core/constants/base_url.dart';
import 'package:defcomm/core/error/exception.dart';
import 'package:defcomm/features/messaging/data/datasources/messaging_remote_datasource.dart';
import 'package:defcomm/features/messaging/data/models/message_group_model.dart';
import 'package:defcomm/features/messaging/data/models/message_thread_model.dart';
import 'package:defcomm/features/messaging/data/models/story_models.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class MessagingRemoteDataSourceImpl implements MessagingRemoteDataSource {
  final http.Client client;
  MessagingRemoteDataSourceImpl(this.client);

  final box = GetStorage();
 

  @override
  Future<List<StoryModel>> fetchStories() async {
     final token = box.read("accessToken");
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/user/contact'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token}',
        },
      );


      debugPrint("storylist response: ${response.body}");
      debugPrint("storylist statuscode: ${response.statusCode}");


      if (response.statusCode >= 200 && response.statusCode < 300) {
        final resBody = jsonDecode(response.body);
        final storiesData = resBody['data'] as List;
        
        final stories = storiesData
            .where((storyJson) => storyJson['contact_name'] != null)
            .map((storyJson) => StoryModel.fromJson(storyJson))
            .toList();
            
        return stories;
      } else {
        throw ServerException('Failed to fetch stories!');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<MessageThreadModel>> fetchMessageThreads() async {

    final token = box.read("accessToken");

    try {
      final response = await client.get(
        Uri.parse('$baseUrl/user/chat/lastMessage'), 
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint("last message response: ${response.body}");
      debugPrint("last message statuscode: ${response.statusCode}");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final resBody = jsonDecode(response.body);
        final threadsData = resBody['data'] as List;

        final threads = threadsData
            .map((threadJson) => MessageThreadModel.fromJson(threadJson))
            .toList();

        return threads;
      } else {
        throw ServerException('Failed to fetch message threads!');
      }
    } catch (e, stackTrace) {
      print('Error: $e');
      print('StackTrace: $stackTrace');
      throw ServerException(e.toString());
    }
  }


  // @override
  // Future<List<MessageGroupModel>> getJoinedGroups() async {
  //   final token = box.read("accessToken");
  //   final response = await client.get(
  //     Uri.parse('$baseUrl/user/group'),
  //     headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
  //   );

  //   debugPrint("getjoinedgroups response: ${response.body}");
  //   debugPrint("getjoinedgroups statusCode: ${response.statusCode}");

  //   if (response.statusCode >= 200 && response.statusCode < 300) {
  //     final data = json.decode(response.body)['data'] as List;
  //     return data.map((item) => MessageGroupModel.fromJson(item)).toList();
  //   } else {
  //     throw ServerException('Failed to load groups');
  //   }
  // }

  @override
Future<List<MessageGroupModel>> getJoinedGroups() async {
  final token = box.read("accessToken");
  
  try {
    final response = await client.get(
      Uri.parse('$baseUrl/user/group'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
    );

    debugPrint("Group API Status: ${response.statusCode}");

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      
      final List<dynamic> data = jsonResponse['data'] ?? [];

      debugPrint("🔢 Items found in JSON: ${data.length}");

      final List<MessageGroupModel> groups = data.map((item) {
        return MessageGroupModel.fromJson(item as Map<String, dynamic>);
      }).toList();

      return groups;
    } else {
      debugPrint("❌ Server Error: ${response.body}");
      throw ServerException('Failed to load groups: ${response.statusCode}');
    }
  } catch (e, stacktrace) {
    debugPrint("❌ Data Source Crash: $e");
    debugPrint("Stacktrace: $stacktrace");
    throw ServerException(e.toString());
  }
}
}