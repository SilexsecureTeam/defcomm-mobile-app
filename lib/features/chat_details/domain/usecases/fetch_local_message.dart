// Add this UseCase
import 'package:defcomm/features/chat_details/data/datasources/chat_detail_local_data_source.dart';
import 'package:defcomm/features/chat_details/domain/entities/chat_message.dart';

class FetchLocalMessages {
  final ChatDetailLocalDataSource localDataSource;
  FetchLocalMessages(this.localDataSource);

  Future<List<ChatMessage>> call(String chatUserId) {
    return localDataSource.getLocalMessages(chatUserId: chatUserId);
  }
}