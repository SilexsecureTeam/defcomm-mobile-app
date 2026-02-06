import 'package:defcomm/core/di/service_initilaizer.dart'
    show startPusherForUser;
import 'package:defcomm/core/life_cycles/call_life_cycle_anager.dart';
import 'package:defcomm/core/pusher/pusher_service.dart';
import 'package:defcomm/core/securty/log_camera_monitoring.dart';
import 'package:defcomm/core/securty/security_overlay.dart';
import 'package:defcomm/core/services/ccallkit_service.dart';
import 'package:defcomm/core/services/front_camera_monitoring_service.dart';
import 'package:defcomm/core/services/screen_security_manager.dart';
import 'package:defcomm/core/services/secure_file_service.dart';
import 'package:defcomm/core/services/security_reporter.dart';
import 'package:defcomm/features/app_navigation/presentation/pages/home_navr.dart';
import 'package:defcomm/features/calling/call_control_constants.dart';
import 'package:defcomm/features/calling/presentation/bloc/call_bloc.dart';
import 'package:defcomm/features/calling/presentation/bloc/call_event.dart' hide CallEvent;
import 'package:defcomm/features/calling/presentation/pages/recieve_cals.dart';
import 'package:defcomm/features/calling/presentation/pages/secure_calling.dart';
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
import 'package:defcomm/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:defcomm/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:defcomm/features/signin/presentation/bloc/auth_bloc.dart';
import 'package:defcomm/features/splash/presentation/pages/unified.dart';
import 'package:defcomm/init_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_storage/get_storage.dart';

import 'dart:convert';

import 'core/notification/local_notification_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

late final LocalNotificationService localNotificationService;

final frontCameraMonitoringService = FrontCameraMonitoringService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  // await GetStorage().erase();

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

  localNotificationService = LocalNotificationService();
  await localNotificationService.init(_onNotificationTap);

  if (isLoggedIn) {
    try {
      await startPusherForUser(token: token!, userId: userEnId!);
    } catch (e) {
      debugPrint("Failed to restart Pusher on app launch: $e");
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupCallKitListener(); 

    // WidgetsBinding.instance.addPostFrameCallback((_) async {

    //    await Future.delayed(const Duration(seconds: 1));
    //    try {
    //     await frontCameraMonitoringService.start(
    //     onSuspiciousCaptureDetected: () async {
    //       Fluttertoast.showToast(msg: "Camera event logged successfully");

    //       // final ctx = navigatorKey.currentState?.overlay?.context;
    //       // if (ctx != null) {
    //       //   SecurityOverlay().show(
    //       //     ctx,
    //       //     reason: "Possible photographing activity detected.",
    //       //   );
    //       // }

    //       await logCameraEventSecurely();
    //     },
    //   );
    //    } catch (e) {
    //     debugPrint("⚠️ Camera Service Failed to Start (Expected in Debug/Simulator): $e");
    //    }

      
    // });
  }

  void _setupCallKitListener() {
    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) async {
      if (event == null) return;

      switch (event.event) {
        case Event.actionCallAccept:
          debugPrint("📞 User Accepted Call via CallKit");
          
        
          final data = event.body['extra'] ?? event.body;
          final String meetingId = data['meetingId'] ?? '';
          final String callerName = data['callerName'] ?? 'Unknown';
          final String peerIdEn = data['callerId'] ?? '';

          navigatorKey.currentState?.push(
            MaterialPageRoute(
              settings: const RouteSettings(name: 'secure_call'),
              builder: (_) => BlocProvider.value(
                value: serviceLocator<CallBloc>(),
                child: SecureCallingScreen(
                  isCaller: false, // You are the receiver
                  meetingId: meetingId,
                  otherUserName: callerName,
                  peerIdEn: peerIdEn,
                ),
              ),
            ),
          );
          navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (context) => RecieveCals() )
          );
          break;

        case Event.actionCallDecline:
          debugPrint("📞 User Declined Call via CallKit");
           await CallKitService.endAllCalls();
          break;
          
        case Event.actionCallEnded:
           await CallKitService.endAllCalls();
           break;

        default:
          break;
      }
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
    }
    
    else if (state == AppLifecycleState.detached || state == AppLifecycleState.paused) {
      debugPrint("🛑 App Paused/Killed.");
      
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
