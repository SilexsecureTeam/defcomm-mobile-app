String buildSingleCallRoomId(String a, String b) {
  final list = [a, b]..sort();
  return 'call_user_${list[0]}_${list[1]}';
}

String buildGroupCallRoomId(String groupIdEn) {
  return 'call_group_$groupIdEn';
}
