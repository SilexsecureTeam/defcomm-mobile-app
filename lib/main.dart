import 'package:defcomm/core/di/service_initilaizer.dart'
    show startPusherForUser;
import 'package:defcomm/core/services/ws_foreground_service.dart'
    show initWsForegroundTask, startWsForegroundService, updateWsServiceUserData;
import 'package:defcomm/core/life_cycles/call_life_cycle_anager.dart';
import 'package:defcomm/core/pusher/pusher_service.dart';
import 'package:defcomm/core/securty/log_camera_monitoring.dart';
import 'package:defcomm/core/securty/security_overlay.dart';
import 'package:defcomm/core/services/front_camera_monitoring_service.dart';
import 'package:defcomm/core/services/secure_file_service.dart';
import 'package:defcomm/features/app_navigation/presentation/pages/home_navr.dart';
import 'package:defcomm/features/chat_details/data/models/chat_user_model.dart';
import 'package:defcomm/features/chat_details/domain/usecases/send_message.dart';
import 'package:defcomm/features/chat_details/presentation/bloc/chat_detail_bloc.dart';
import 'package:defcomm/features/chat_details/presentation/pages/chat_screen.dart';
import 'package:defcomm/features/group_chat/presentation/bloc/group_chat_bloc.dart';
import 'package:defcomm/features/group_chat/presentation/pages/group_chat_screen.dart';
import 'package:defcomm/features/groups/domain/entities/group_entity.dart';
import 'package:defcomm/features/groups/presentation/bloc/group_bloc.dart';
import 'package:defcomm/features/groups/presentation/bloc/group_member_bloc.dart';
import 'package:defcomm/features/home/presentation/pages/home_screen.dart';
import 'package:defcomm/features/linked_devices/presenation/blocs/linked_devices_bloc.dart';
import 'package:defcomm/features/messaging/presentation/bloc/messaging_bloc.dart';
import 'package:defcomm/features/messaging/presentation/bloc/messaging_event.dart';
import 'package:defcomm/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:defcomm/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:defcomm/features/signin/presentation/bloc/auth_bloc.dart';
import 'package:defcomm/features/splash/presentation/pages/unified.dart';
import 'package:defcomm/init_dependencies.dart';
import 'package:defcomm/features/calling/presentation/bloc/call_bloc.dart';
import 'package:defcomm/features/calling/presentation/bloc/call_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';

import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:defcomm/core/services/fcm_service.dart';
import 'core/notification/local_notification_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

late final LocalNotificationService localNotificationService;

final frontCameraMonitoringService = FrontCameraMonitoringService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  initWsForegroundTask();
  // await GetStorage().erase();

  // Initialize Firebase — guarded for no-Google (ODM) devices
  bool hasFirebase = false;
  try {
    await Firebase.initializeApp();
    hasFirebase = true;
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('⚠️ Firebase unavailable (likely no Google Services): $e');
  }

  await SecureFileService().init();

  initDependencies();

  final box = GetStorage();
  final String? token = box.read('accessToken');
  final String? userEnId = box.read('userEnId');

  // box.remove('recent_calls_cache');

  final bool isLoggedIn =
      token != null &&
      token.isNotEmpty &&
      userEnId != null &&
      userEnId.isNotEmpty;

  try {
    localNotificationService = LocalNotificationService();
    await localNotificationService.init(_onNotificationTap);
    debugPrint("✅ Local notification service initialized");
  } catch (e, stack) {
    debugPrint("❌ Failed to initialize local notifications: $e");
    debugPrint("Stack: $stack");
    // Continue app launch even if notifications fail
  }

  // Request battery optimization exemption so Android/OEMs don't kill the
  // background service (Pusher keepalive) on Samsung/Xiaomi/Huawei devices.
  try {
    final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
    if (!batteryStatus.isGranted) {
      await Permission.ignoreBatteryOptimizations.request();
    }
  } catch (e) {
    debugPrint("Battery optimization request error: $e");
  }

  // Request SYSTEM_ALERT_WINDOW — required by flutter_callkit_incoming to
  // display the full-screen incoming call overlay over the lock screen.
  // Without this, CallKit shows nothing when the screen is off.
  try {
    if (!await Permission.systemAlertWindow.isGranted) {
      await Permission.systemAlertWindow.request();
    }
  } catch (e) {
    debugPrint("System alert window request error: $e");
  }

  // Request exact alarm permission (Android 12+) — ensures alarm-triggered
  // wake can fire on time, which helps the background service stay live.
  try {
    if (!await Permission.scheduleExactAlarm.isGranted) {
      await Permission.scheduleExactAlarm.request();
    }
  } catch (e) {
    debugPrint("Schedule exact alarm request error: $e");
  }

  if (isLoggedIn) {
    // Initialize FCM first (only if Firebase / Google available)
    if (hasFirebase) {
      try {
        debugPrint("🚀 Initializing FCM service...");
        final fcmService = FcmService();
        await fcmService.init(
          authToken: token!,
          onNotificationTap: _onNotificationTap,
        );
      } catch (e, stack) {
        debugPrint("❌ Failed to initialize FCM: $e");
        debugPrint("Stack: $stack");
      }
    }

    // Start WS foreground service (primary background channel)
    try {
      if (!await Permission.notification.isGranted) {
        await Permission.notification.request();
      }
      debugPrint("🚀 Starting WS foreground service...");
      await startWsForegroundService();
      updateWsServiceUserData(
        token: token!,
        userId: userEnId!,
        groupIds: [],  // Groups get populated later via Pusher resync
      );
    } catch (e) {
      debugPrint("❌ Failed to start WS foreground service: $e");
    }

    // Initialize Pusher after a small delay to avoid connection race
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      debugPrint("🚀 Initializing Pusher service...");
      await startPusherForUser(token: token!, userId: userEnId!);
    } catch (e, stack) {
      debugPrint("❌ Failed to restart Pusher on app launch: $e");
      debugPrint("Stack: $stack");
    }
  }

  // final screenSecurityManager = ScreenSecurityManager();

  // await screenSecurityManager.initialize(
  //   onScreenshotAttempt: () async {
  //     debugPrint('🚨 Screenshot attempt detected');

  //     // Report to backend
  //     final success = await serviceLocator<SecurityReporter>().report(
  //       screen: 'global',
  //     );

  //     debugPrint(
  //       success ? '✅ Screenshot report sent' : '❌ Screenshot report failed',
  //     );
  //   },
  // );

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

Future<void> _onNotificationTap(String? payload) async {
  if (payload == null) return;

  try {
    final data = jsonDecode(payload) as Map<String, dynamic>;
    final kind = data['kind'] as String?; // 'user' or 'group'
    final chatIdEn = data['chatIdEn'] as String?;
    final chatName = data['chatName'] as String?;

    if (chatIdEn == null) return;

    // We use the global navigatorKey because we don't have a BuildContext here
    if (kind == 'user') {
      navigatorKey.currentState?.pushNamed(
        '/chat',
        arguments: {
          'chatUserId': chatIdEn,
          'chatUserName': chatName ?? 'Unknown',
        },
      );
    } else if (kind == 'group') {
      navigatorKey.currentState?.pushNamed(
        '/group-chat',
        arguments: {'groupIdEn': chatIdEn, 'groupName': chatName ?? 'Group'},
      );
    }
  } catch (e) {
    debugPrint('Error parsing notification payload: $e');
  }
}



class MyApp extends StatefulWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp>  with WidgetsBindingObserver{

  static const _oemChannel =
      MethodChannel('come.deffcom.chatapp/oem_battery');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Wake screen via legacy background service signal.
    FlutterBackgroundService().on('wakeScreen').listen((_) {
      _oemChannel.invokeMethod('wakeScreen').catchError((_) {});
    });

    // Wake screen via WS foreground task signal.
    FlutterForegroundTask.addTaskDataCallback(_onWsTaskData);
    // Tell the task handler the app is currently in the foreground.
    FlutterForegroundTask.sendDataToTask({'action': 'appForeground'});

    // On Android 14+ USE_FULL_SCREEN_INTENT must be explicitly granted for
    // incoming call notifications to turn the screen on.  Request it now.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureFullScreenIntentPermission();
    });
  }

  // @override
  // void dispose() {
  //   WidgetsBinding.instance.removeObserver(this);
  //   super.dispose();
  // }

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) async {
  //   if (state == AppLifecycleState.detached || state == AppLifecycleState.paused) {
  //     debugPrint("🛑 App is sleeping/dying. Disconnecting Foreground Pusher...");
      
  //     if (serviceLocator.isRegistered<PusherService>()) {
  //       try {
  //         serviceLocator<PusherService>().disconnect(); 
  //       } catch (e) {
  //         debugPrint("Error disconnecting: $e");
  //       }
  //     }
  //   }
  // }

   @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    final service = FlutterBackgroundService();

    if (state == AppLifecycleState.resumed) {
      debugPrint("🔄 App Resumed.");
      FlutterForegroundTask.sendDataToTask({'action': 'appForeground'});
      service.invoke("setAsForeground");

      if (serviceLocator.isRegistered<PusherService>()) {
        try {
          final pusher = serviceLocator<PusherService>();
          await pusher.init(); 
          
          final box = GetStorage();
          final String? userId = box.read('userEnId');
          if (userId != null) {
             pusher.subscribeToUserChannel(userId);
          }
        } catch (e) {
          debugPrint("Error reconnecting pusher: $e");
        }
      }

      try {
        serviceLocator<MessagingBloc>().add(FetchMessageThreadsEvent());
      } catch (e) {
        debugPrint("Error refreshing threads on resume: $e");
      }
    }
    
    else if (state == AppLifecycleState.inactive) {
      debugPrint("💤 App Inactive — enabling background notifications.");
      FlutterForegroundTask.sendDataToTask({'action': 'appBackground'});
      service.invoke("setAsBackground");
    }

    else if (state == AppLifecycleState.hidden) {
      debugPrint("🌑 App Hidden — enabling background notifications.");
      FlutterForegroundTask.sendDataToTask({'action': 'appBackground'});
      service.invoke("setAsBackground");
    }

    else if (state == AppLifecycleState.paused ||
             state == AppLifecycleState.detached) {
      debugPrint("🛑 App Paused/Killed.");
      FlutterForegroundTask.sendDataToTask({'action': 'appBackground'});
      service.invoke("setAsBackground");

      if (serviceLocator.isRegistered<PusherService>()) {
        try {
          serviceLocator<PusherService>().disconnect();
        } catch (e) {
          debugPrint("Error disconnecting: $e");
        }
      }
    }
  }

  Future<void> _ensureFullScreenIntentPermission() async {
    try {
      final bool granted = await _oemChannel.invokeMethod<bool>(
            'canUseFullScreenIntent') ??
          true;
      if (!granted) {
        await _oemChannel.invokeMethod('requestFullScreenIntentPermission');
      }
    } catch (_) {}
  }

  void _onWsTaskData(Object data) {
    if (data is! Map) return;
    final event = data['event'] as String? ?? '';

    if (event == 'wakeScreen') {
      _oemChannel.invokeMethod('wakeScreen').catchError((_) {});
      return;
    }

    if (event == 'endCalls') {
      FlutterCallkitIncoming.endAllCalls();
      try { serviceLocator<CallBloc>().add(const CallEnded()); } catch (_) {}
      navigatorKey.currentState?.popUntil(
        (route) => route.settings.name != 'secure_call',
      );
      return;
    }

    if (event == 'incomingCall') {
      _oemChannel.invokeMethod('wakeScreen').catchError((_) {});
      final callerId  = data['callerId']  as String? ?? '';
      final callerName = data['callerName'] as String? ?? 'Unknown';
      final meetingId  = data['meetingId']  as String? ?? '';
      FlutterCallkitIncoming.showCallkitIncoming(CallKitParams(
        id: meetingId.isNotEmpty ? meetingId : DateTime.now().millisecondsSinceEpoch.toString(),
        nameCaller: callerName,
        appName: 'Defcomm',
        handle: callerName,
        type: 0,
        duration: 30000,
        textAccept: 'Accept',
        textDecline: 'Decline',
        missedCallNotification: const NotificationParams(
          showNotification: true,
          isShowCallback: true,
          subtitle: 'Missed call',
          callbackText: 'Call back',
        ),
        extra: {
          'meetingId': meetingId,
          'callerId': callerId,
          'callerName': callerName,
        },
        android: const AndroidParams(
          isCustomNotification: false,
          isShowLogo: false,
          isShowFullLockedScreen: true,
          ringtonePath: 'system_ringtone_default',
          backgroundColor: '#1B5E20',
          actionColor: '#4CAF50',
          textColor: '#FFFFFF',
        ),
        ios: const IOSParams(
          iconName: 'CallKitLogo',
          handleType: '',
          supportsVideo: true,
          maximumCallGroups: 2,
          maximumCallsPerCallGroup: 1,
          ringtonePath: 'system_ringtone_default',
        ),
      ));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    FlutterForegroundTask.removeTaskDataCallback(_onWsTaskData);
    super.dispose();
  }

  
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Auth
        BlocProvider(create: (_) => serviceLocator<AuthBloc>()),

        // Messaging screen (stories + threads)
        BlocProvider<MessagingBloc>.value(
          value: serviceLocator<MessagingBloc>(),
        ),

        BlocProvider<ChatDetailBloc>.value(
          value: serviceLocator<ChatDetailBloc>(),
        ),

        BlocProvider(create: (_) => serviceLocator<GroupBloc>()),

        BlocProvider<SettingsBloc>(
          create: (context) => serviceLocator<SettingsBloc>(),
        ),

        BlocProvider<ProfileBloc>(
          create: (context) => serviceLocator<ProfileBloc>(),
        ),

        BlocProvider<LinkedDevicesBloc>(
          create: (context) => serviceLocator<LinkedDevicesBloc>(),
        ),

        BlocProvider<GroupChatBloc>.value(
          value: serviceLocator<GroupChatBloc>(),
        ),

        BlocProvider<GroupMembersBloc>.value(
          value: serviceLocator<GroupMembersBloc>(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Defcomm Mobile',
        navigatorKey: navigatorKey, // 🔥 important for notification navigation
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        ),

        builder: (context, child) {
          
          return CallLifecycleManager(child: child!);
        },
        // home: const UnifiedSplashScreen(),
        home: widget.isLoggedIn ? const HomeNavr() : const UnifiedSplashScreen(),

        routes: {
          '/chat': (context) {
            final args =
                ModalRoute.of(context)!.settings.arguments
                    as Map<String, dynamic>?;

            final chatUserId = args?['chatUserId'] as String? ?? '';
            final chatUserName = args?['chatUserName'] as String? ?? 'Unknown';

            final user = ChatUser(
              id: chatUserId,
              name: chatUserName,
              imageUrl: '', 
              role: '',
            );

            return ChatScreen(user: user);
          },

          '/group-chat': (context) {
            final args =
                ModalRoute.of(context)!.settings.arguments
                    as Map<String, dynamic>?;

            final groupIdEn = args?['groupIdEn'] as String? ?? '';
            final groupName = args?['groupName'] as String? ?? 'Group';

            final group = GroupEntity(
              id: '',
              companyName: '',
              groupId: groupIdEn,
              groupName: groupName,
              invitationDate: '',
              status: '',
              isPending: false,
            );

            debugPrint('Navigating to group chat: $groupName ($groupIdEn)');

            return GroupChatScreen(
              groupIdEn:
                  groupIdEn, 
              groupName: groupName,
              group: group,
            );
          },
        },
      ),
    );
  }
}
