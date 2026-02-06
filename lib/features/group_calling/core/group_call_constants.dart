const String kGroupCallInvitePrefix = '__DEFCOMM_GROUP_CALL_INVITE_v1__|';
const String kGroupCallAccepted = '__DEFCOMM_GROUP_CALL_ACCEPTED_v1__';
const String kGroupCallRejected = '__DEFCOMM_GROUP_CALL_REJECTED_v1__';
const String kGroupCallEnded = '__DEFCOMM_GROUP_CALL_ENDED_v1__';
const String kGroupCallMute = '__DEFCOMM_GROUP_CALL_MUTE_v1__|';   
const String kGroupCallUnmute = '__DEFCOMM_GROUP_CALL_UNMUTE_v1__|';



extension GroupCallParsing on String? {
  bool get isGroupCallInvite => this != null && this!.startsWith(kGroupCallInvitePrefix);
  bool get isGroupCallEnded => this != null && this!.startsWith(kGroupCallEnded);
  bool get isGroupControlSignal => this != null && (this!.startsWith(kGroupCallMute) || this!.startsWith(kGroupCallUnmute));

  String get extractRoomId {
    if (this == null) return '';
    return this!.replaceAll(kGroupCallInvitePrefix, '');
  }
}
