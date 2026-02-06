import 'dart:convert';
import 'package:defcomm/core/constants/base_url.dart';
import 'package:defcomm/core/error/exception.dart';
import 'package:defcomm/features/groups/data/models/group_member_res.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import '../models/group_model.dart';

abstract class GroupRemoteDataSource {
  Future<List<GroupModel>> getJoinedGroups();
  Future<List<GroupModel>> getPendingGroups();
  Future<void> acceptInvitation(String groupId);
  Future<void> declineInvitation(String groupId);

  Future<GroupMembersResponse> fetchGroupMembers(String groupId);
}

class GroupRemoteDataSourceImpl implements GroupRemoteDataSource {
  final http.Client client;

  GroupRemoteDataSourceImpl({required this.client});

  final box = GetStorage();

  

  @override
  Future<List<GroupModel>> getJoinedGroups() async {
    final token = box.read("accessToken");
    final response = await client.get(
      Uri.parse('$baseUrl/user/group'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );

    debugPrint("getjoinedgroups response: ${response.body}");
    debugPrint("getjoinedgroups statusCode: ${response.statusCode}");

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = json.decode(response.body)['data'] as List;
      return data.map((item) => GroupModel.fromJson(item)).toList();
    } else {
      throw ServerException('Failed to load groups');
    }
  }

  @override
  Future<List<GroupModel>> getPendingGroups() async {
    final token = box.read("accessToken");
    final response = await client.get(
      Uri.parse('$baseUrl/user/group/pending'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );

    debugPrint("getPendingGroups response: ${response.body}");
    debugPrint("getPendingGroups statusCode: ${response.statusCode}");

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = json.decode(response.body)['data'] as List;
      return data.map((item) => GroupModel.fromJson(item)).toList();
    } else {
      throw ServerException('Failed to load pending groups');
    }
  }

  @override
  Future<void> acceptInvitation(String groupId) async {
    final token = box.read("accessToken");
    final response = await client.get(
      Uri.parse('$baseUrl/user/group/${groupId}/accept'),
      headers: {'Authorization': 'Bearer $token'},
    );
    debugPrint("$groupId");
    debugPrint("accept group: ${response.statusCode}");
    debugPrint("accept group: ${response.body}");
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ServerException('Failed to accept invitation');
    }
  }

  @override
  Future<void> declineInvitation(String groupId) async {
    final token = box.read("accessToken");
    final response = await client.get(
      Uri.parse('$baseUrl/user/group/${groupId}/decline/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    debugPrint("decline group: ${response.body}");
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ServerException('Failed to decline invitation');
    }
  }

   @override
  Future<GroupMembersResponse> fetchGroupMembers(String groupId) async {
    final token = box.read("accessToken");
     final response = await client.get(
      Uri.parse("$baseUrl/user/group/member/$groupId"),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );
    debugPrint("group members response: ${response.body}");
    debugPrint("group members statusCode: ${response.statusCode}");

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final jsonMap = json.decode(response.body) as Map<String, dynamic>;
      return GroupMembersResponse.fromJson(jsonMap);
    } else {
      throw Exception('Failed to fetch group members: ${response.statusCode}');
    }
  }
}