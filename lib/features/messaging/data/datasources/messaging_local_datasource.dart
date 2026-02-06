import 'dart:convert';
import 'package:defcomm/features/messaging/data/models/story_models.dart';
import 'package:get_storage/get_storage.dart';
import '../../data/models/message_thread_model.dart';
import '../../data/models/message_group_model.dart';
import 'package:get_storage/get_storage.dart';
import '../models/message_thread_model.dart';
import '../models/message_group_model.dart';

abstract interface class MessagingLocalDataSource {
  Future<void> cacheStories(List<StoryModel> stories);
  List<StoryModel> getLastStories();

  Future<void> cacheThreads(List<MessageThreadModel> threads);
  List<MessageThreadModel> getLastThreads();

  Future<void> cacheGroups(List<MessageGroupModel> groups);
  List<MessageGroupModel> getLastGroups();
}

class MessagingLocalDataSourceImpl implements MessagingLocalDataSource {
  final box = GetStorage();

  final String _kStoriesKey = 'cached_stories';
  final String _kThreadsKey = 'cached_threads';
  final String _kGroupsKey = 'cached_groups';

  @override
  Future<void> cacheStories(List<StoryModel> stories) async {
    final List<Map<String, dynamic>> jsonList = 
        stories.map((e) => e.toMap()).toList();
    await box.write(_kStoriesKey, jsonList);
  }

  @override
  List<StoryModel> getLastStories() {
    final rawData = box.read(_kStoriesKey);
    if (rawData != null && rawData is List) {
      return rawData
          .map((e) => StoryModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  @override
  Future<void> cacheThreads(List<MessageThreadModel> threads) async {
    final List<Map<String, dynamic>> jsonList = 
        threads.map((e) => e.toMap()).toList();
    await box.write(_kThreadsKey, jsonList);
  }

  @override
  List<MessageThreadModel> getLastThreads() {
    final rawData = box.read(_kThreadsKey);
    if (rawData != null && rawData is List) {
      return rawData
          .map((e) => MessageThreadModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  @override
  Future<void> cacheGroups(List<MessageGroupModel> groups) async {
    final List<Map<String, dynamic>> jsonList = 
        groups.map((e) => e.toMap()).toList(); 
    await box.write(_kGroupsKey, jsonList);
  }

  @override
  List<MessageGroupModel> getLastGroups() {
    final rawData = box.read(_kGroupsKey);
    if (rawData != null && rawData is List) {
      return rawData
          .map((e) => MessageGroupModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }
}