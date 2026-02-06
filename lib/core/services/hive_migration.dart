import 'package:defcomm/features/messaging/domain/entities/message_thread.dart';
import 'package:hive/hive.dart';

Future<void> deduplicateThreads(Box<MessageThread> box) async {
  final Map<String, MessageThread> unique = {};

  for (final t in box.values) {
    unique[t.id ?? ""] = t;
  }

  await box.clear();
  await box.putAll(unique);
}
