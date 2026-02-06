// lib/features/calling/call_control_constants.dart

/// These are special texts we send as *hidden* messages to control calls.
/// They must be unique so normal users never type them accidentally.
const String kCallControlInvitePrefix = '__call_control__invite|';
const String kCallControlRejected     = '__DEFCOMM_CALL_REJECTED_v1__';
const String kCallControlEnded        = '__DEFCOMM_CALL_ENDED_v1__';
const String kCallControlAccepted     = 'call_accepted';


String? getCallStatusMessage(String content) {
    if (content.startsWith(kCallControlInvitePrefix)) {
      return "Incoming Call"; // or "Video/Voice Call started"
    }
    if (content == kCallControlAccepted) {
      return "Call Accepted";
    }
    if (content == kCallControlRejected) {
      return "Call Rejected";
    }
    if (content == kCallControlEnded) {
      return "Call Ended";
    }
    return null; // It's a normal chat message
  }
