import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../../core/error/failures.dart';
import '../entities/group_chat_page.dart';
import '../repositories/group_chat_repository.dart';

class FetchGroupMessages
    implements UseCase<GroupChatPage, FetchGroupMessagesParams> {
  final GroupChatRepository repository;

  FetchGroupMessages(this.repository);

  @override
  Future<Either<Failure, GroupChatPage>> call(
    FetchGroupMessagesParams params,
  ) {
    return repository.fetchGroupMessages(
      groupUserIdEn: params.groupUserIdEn,
      page: params.page,
    );
  }
}

class FetchGroupMessagesParams extends Equatable {
  final String groupUserIdEn; 
  final int page;

  const FetchGroupMessagesParams({
    required this.groupUserIdEn,
    required this.page,
  });

  @override
  List<Object?> get props => [groupUserIdEn, page];
}
