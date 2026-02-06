import 'package:defcomm/core/notification/local_notifiction.dart';
import 'package:defcomm/core/pusher/pusher_service.dart';
import 'package:defcomm/core/services/background_pusher_service.dart';
import 'package:defcomm/features/chat_details/presentation/bloc/chat_detail_bloc.dart';
import 'package:defcomm/features/group_chat/domain/repositories/group_chat_repository.dart';
import 'package:defcomm/features/group_chat/presentation/bloc/group_chat_bloc.dart';
import 'package:defcomm/features/groups/domain/usecases/get_group.dart';
import 'package:defcomm/features/messaging/domain/usecases/get_message_groups.dart';
import 'package:defcomm/features/messaging/presentation/bloc/messaging_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:get_it/get_it.dart';
import 'package:get_storage/get_storage.dart';

final serviceLocator = GetIt.instance;

Future<void> startPusherForUser({
  required String token,
  required String userId,
}) async {
  debugPrint("🚀 STARTING PUSHER SETUP...");

  if (serviceLocator.isRegistered<PusherService>()) {
    debugPrint("⚠️ PusherService already registered. Cleaning up...");
    try {
      final old = serviceLocator<PusherService>();
      old.dispose();
      serviceLocator.unregister<PusherService>();
    } catch (e) {
      debugPrint("Error unregistering old Pusher: $e");
    }
  }

  // 2. CREATE NEW SERVICE
  final pusher = PusherService(
    appKey: 'l4ewjdxj5hilgin4smsv',
    cluster: 'mt1',
    host: 'backend.defcomm.ng',
    authEndpoint: 'https://backend.defcomm.ng/api/broadcasting/auth',
    token: token,
    currentUserId: userId,
    messagingBloc: serviceLocator<MessagingBloc>(),
    chatDetailBloc: serviceLocator<ChatDetailBloc>(),
    groupChatBloc: serviceLocator<GroupChatBloc>(),
    localNotificationService: serviceLocator<LocalNotificationService>(),
    getJoinedGroups: serviceLocator<GetMessageJoinedGroups>(),
  );

  serviceLocator.registerSingleton<PusherService>(pusher);

  debugPrint("🟢 Initializing Foreground Pusher...");
  await pusher.init();
  pusher.subscribeToUserChannel(userId);

  List<String> groupIds = [];
  try {
    debugPrint("🔍 Fetching Joined Groups...");
    final getJoinedGroups = serviceLocator<GetMessageJoinedGroups>();
    final result = await getJoinedGroups();

    result.fold((l) => debugPrint("❌ Failed to fetch groups: ${l.message}"), (
      groups,
    ) {
      debugPrint("✅ Found ${groups.length} groups.");
      for (var g in groups) {
        if (g.groupId.isNotEmpty) {
          groupIds.add(g.groupId);
          // Subscribe Foreground
          pusher.subscribeToGroupChannel(g.groupId);
        }
      }
    });
  } catch (e) {
    debugPrint("❌ Error fetching groups: $e");
  }


  final box = GetStorage();
  await box.write('background_group_ids', groupIds);
  await box.write('accessToken', token);
  await box.write('userEnId', userId);
  await box.save(); 

    await Future.delayed(const Duration(milliseconds: 500)); 

  try {
    debugPrint("🚀 Launching Background Service...");
     final service = FlutterBackgroundService();
    var isRunning = await service.isRunning();


    if (!isRunning) {
        await initializeBackgroundService(token, userId, groupIds);
    } else {
        service.invoke("setUserData", {
           "token": token,
           "userId": userId,
           "groupIds": groupIds
        });
    }
  } catch (e) {
    debugPrint("❌ Failed to start background service: $e");
  }

  try {
    if (!serviceLocator.isRegistered<LocalNotificationService>()) {
      await serviceLocator<LocalNotificationService>().init();
    }
  } catch (e) {
    debugPrint("Local Notif Init warning: $e");
  }
}

Future<void> stopPusherForCurrentUser() async {

  if (serviceLocator.isRegistered<PusherService>()) {
    final p = serviceLocator<PusherService>();
    p.dispose();
    serviceLocator.unregister<PusherService>();
  }

  final service = FlutterBackgroundService();
  var isRunning = await service.isRunning();
  if (isRunning) {
    service.invoke("stopService");
  }
}
