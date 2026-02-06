import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/chat_page.dart';
import '../repositories/chat_detail_repository.dart';

class FetchMessages implements UseCase<ChatPage, FetchMessagesParams> {
  final ChatDetailRepository repository;
  FetchMessages(this.repository);

  @override
  Future<Either<Failure, ChatPage>> call(FetchMessagesParams params) async {
    return await repository.fetchMessages(
      chatUserId: params.chatUserId,
      page: params.page,
    );
  }
}

class FetchMessagesParams {
  final String chatUserId;
  final int page;
  FetchMessagesParams({required this.chatUserId, required this.page});
}