import 'dart:convert';
import 'package:defcomm/features/groups/data/models/group_member_model.dart';
import 'package:defcomm/features/groups/data/models/group_member_res.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
// Import your specific model files
import 'package:defcomm/core/constants/base_url.dart';
import 'package:defcomm/core/error/exception.dart';
import 'package:defcomm/features/messaging/data/models/story_models.dart';
// Make sure to import your GroupMemberModel and GroupMembersResponse

abstract class UnknownMembersRemoteDataSource {
  // CHANGE 1: Return specific types, not dynamic
  Future<List<StoryModel>> fetchMyContacts(); 
  Future<List<GroupMemberModel>> fetchGroupMembers(String groupId); 
}

class UnknownMembersRemoteDataSourceImpl implements UnknownMembersRemoteDataSource {
  final http.Client client;
  final box = GetStorage();

  UnknownMembersRemoteDataSourceImpl(this.client);

  @override
  Future<List<StoryModel>> fetchMyContacts() async {
    final token = box.read("accessToken");
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/user/contact'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      debugPrint("My contacts: ${response.body}");


      if (response.statusCode >= 200 && response.statusCode < 300) {
        final resBody = jsonDecode(response.body);
        final storiesData = resBody['data'] as List;
        
        // This converts JSON -> StoryModel. Perfect.
        return storiesData
            .where((storyJson) => storyJson['contact_name'] != null)
            .map((storyJson) => StoryModel.fromJson(storyJson))
            .toList();
      } else {
        throw ServerException('Failed to fetch stories!');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<GroupMemberModel>> fetchGroupMembers(String groupId) async {
    final token = box.read("accessToken");
    try {
      final response = await client.get(
        Uri.parse("$baseUrl/user/group/member/$groupId"),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      );
      debugPrint("My group contacts: ${response.body}");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonMap = json.decode(response.body) as Map<String, dynamic>;
        
        // CHANGE 2: Extract the LIST from the Response object here
        // Assuming GroupMembersResponse has a property called 'data' or 'members' 
        // that holds the List<GroupMemberModel>
        final groupResponse = GroupMembersResponse.fromJson(jsonMap);
        
        // You need to return the LIST, not the wrapper
        return groupResponse.members; // <--- Make sure '.data' exists in your GroupMembersResponse
      } else {
        throw Exception('Failed to fetch group members: ${response.statusCode}');
      }
    } catch (e) {
       throw ServerException(e.toString());
    }
  }
}