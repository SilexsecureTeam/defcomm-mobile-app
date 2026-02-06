String resolveThreadId({
  required String chatUserType,
  required String myUserId,
  required String senderId,
  required String receiverId,
  String? groupId,
}) {
  if (chatUserType == 'group' && groupId != null && groupId.isNotEmpty) {
    return groupId;
  }

  return senderId == myUserId ? receiverId : senderId;
}
