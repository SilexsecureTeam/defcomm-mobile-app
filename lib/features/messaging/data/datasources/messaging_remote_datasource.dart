
import 'package:defcomm/features/messaging/data/models/message_group_model.dart';
import 'package:defcomm/features/messaging/data/models/message_thread_model.dart';
import 'package:defcomm/features/messaging/data/models/story_models.dart';

abstract interface class MessagingRemoteDataSource {
  Future<List<StoryModel>> fetchStories();

  Future<List<MessageThreadModel>> fetchMessageThreads();
  Future<List<MessageGroupModel>> getJoinedGroups();
}