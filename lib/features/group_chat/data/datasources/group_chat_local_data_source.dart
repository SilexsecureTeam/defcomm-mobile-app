import 'package:get_storage/get_storage.dart';
import '../models/group_chat_message_model.dart';

abstract interface class GroupChatLocalDataSource {
  Future<List<GroupChatMessageModel>> getLocalMessages(String groupId);
  Future<void> cacheMessages(String groupId, List<GroupChatMessageModel> messages);
  Future<void> addMessage(String groupId, GroupChatMessageModel message);
}

class GroupChatLocalDataSourceImpl implements GroupChatLocalDataSource {

  GroupChatLocalDataSourceImpl();

  String _getKey(String groupId) => "group_chat_$groupId";



  final box = GetStorage();

  @override
  Future<List<GroupChatMessageModel>> getLocalMessages(String groupId) async {
    final key = _getKey(groupId);
    if (!box.hasData(key)) return [];

    final List<dynamic> jsonList = box.read(key);
    
    return jsonList
        .map((e) => GroupChatMessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> cacheMessages(String groupId, List<GroupChatMessageModel> messages) async {
    final key = _getKey(groupId);
    final List<Map<String, dynamic>> jsonList = 
        messages.map((m) => m.toMap()).toList();
        
    await box.write(key, jsonList);
  }

  @override
  Future<void> addMessage(String groupId, GroupChatMessageModel message) async {
    final currentList = await getLocalMessages(groupId);
    
    currentList.insert(0, message);
    
    await cacheMessages(groupId, currentList);
  }
}