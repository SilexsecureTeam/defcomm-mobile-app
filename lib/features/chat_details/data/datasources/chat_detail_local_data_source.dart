import 'dart:convert';
import 'package:defcomm/features/chat_details/data/models/chat_messge_model.dart';
import 'package:get_storage/get_storage.dart';

abstract interface class ChatDetailLocalDataSource {
  Future<List<ChatMessageModel>> getLocalMessages({required String chatUserId});
  Future<void> cacheMessages({required String chatUserId, required List<ChatMessageModel> messages});
  Future<void> addMessage({required String chatUserId, required ChatMessageModel message});

  List<ChatMessageModel> getLocalMessagesSync({required String chatUserId}); 
}

class ChatDetailLocalDataSourceImpl implements ChatDetailLocalDataSource {
  final GetStorage box;

  ChatDetailLocalDataSourceImpl(this.box);

  String _getKey(String chatUserId) => "chat_messages_$chatUserId";

  @override
  Future<List<ChatMessageModel>> getLocalMessages({required String chatUserId}) async {
    final key = _getKey(chatUserId);
    if (!box.hasData(key)) return [];

    final List<dynamic> jsonList = box.read(key);
    
    // Convert the List of Maps back to List of Models
    return jsonList
        .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> cacheMessages({
    required String chatUserId,
    required List<ChatMessageModel> messages,
  }) async {
    final key = _getKey(chatUserId);
    
    // We store the data as a List of Maps
    final List<Map<String, dynamic>> jsonList = 
        messages.map((m) => m.toMap()).toList();
        
    await box.write(key, jsonList);
  }

  @override
  Future<void> addMessage({required String chatUserId, required ChatMessageModel message}) async {
    // 1. Get current list
    final currentList = await getLocalMessages(chatUserId: chatUserId);
    
    // 2. Add new message to top (assuming index 0 is newest)
    currentList.insert(0, message);
    
    // 3. Save back
    await cacheMessages(chatUserId: chatUserId, messages: currentList);
  }

  @override
  List<ChatMessageModel> getLocalMessagesSync({required String chatUserId}) {
    final key = _getKey(chatUserId);
    if (!box.hasData(key)) return [];

    final List<dynamic> jsonList = box.read(key);
    return jsonList
        .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}