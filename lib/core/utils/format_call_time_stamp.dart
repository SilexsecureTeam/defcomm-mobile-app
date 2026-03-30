String formatCallFullDate(DateTime dateTime) {
  final local = dateTime.toLocal();
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  final dayName = days[local.weekday - 1];
  final month = months[local.month - 1];
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour > 12
      ? local.hour - 12
      : (local.hour == 0 ? 12 : local.hour);
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '$dayName, $day $month · $hour:$minute $period';
}

String formatCallTimestamp(DateTime dateTime) {
  final now = DateTime.now();
  final local = dateTime.toLocal();

  final today = DateTime(now.year, now.month, now.day);
  final callDay = DateTime(local.year, local.month, local.day);

  final difference = today.difference(callDay).inDays;

  if (difference == 0) {
    final hour = local.hour > 12 ? local.hour - 12 : (local.hour == 0 ? 12 : local.hour);
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? "PM" : "AM";
    return "$hour:$minute $period";
  }

  if (difference == 1) {
    return "Yesterday";
  }

  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  final month = months[local.month - 1];
  final day = local.day.toString().padLeft(2, '0');

  return "$day $month";
}
