import '../entities/group_chat_message.dart';
import '../../data/datasources/group_chat_local_data_source.dart';

class FetchLocalGroupMessages {
  final GroupChatLocalDataSource localDataSource;

  FetchLocalGroupMessages(this.localDataSource);

  Future<List<GroupChatMessage>> call(String groupId) {
    return localDataSource.getLocalMessages(groupId);
  }
}