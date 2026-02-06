import 'package:defcomm/core/notification/local_notifiction.dart';
import 'package:defcomm/core/pusher/pusher_service.dart';
import 'package:defcomm/core/services/security_reporter.dart';
import 'package:defcomm/core/services/storage_service.dart';
import 'package:defcomm/core/services/storage_service_impl.dart';
import 'package:defcomm/core/utils/call_manager.dart';
import 'package:defcomm/features/calling/data/datasources/call_remote_data_source.dart';
import 'package:defcomm/features/calling/data/repositories/call_repository_impl.dart';
import 'package:defcomm/features/calling/domain/repositories/call_repository.dart';
import 'package:defcomm/features/calling/domain/usecases/start_call.dart';
import 'package:defcomm/features/calling/presentation/bloc/call_bloc.dart';
import 'package:defcomm/features/chat_details/data/datasources/chat_detail_local_data_source.dart';
import 'package:defcomm/features/chat_details/data/datasources/chat_detail_remote_data_source.dart';
import 'package:defcomm/features/chat_details/data/datasources/chat_detail_remote_data_source_impl.dart';
import 'package:defcomm/features/chat_details/data/repositories/chat_detail_repository_impl.dart';
import 'package:defcomm/features/chat_details/domain/repositories/chat_detail_repository.dart';
import 'package:defcomm/features/chat_details/domain/usecases/fetch_local_message.dart';
import 'package:defcomm/features/chat_details/domain/usecases/fetch_messages.dart';
import 'package:defcomm/features/chat_details/domain/usecases/send_message.dart';
import 'package:defcomm/features/chat_details/presentation/bloc/chat_detail_bloc.dart';
import 'package:defcomm/features/contact/data/datasources/contact_remote_datasource.dart';
import 'package:defcomm/features/contact/data/repositories/contact_repository_impl.dart';
import 'package:defcomm/features/contact/domain/repositories/contact_repository.dart';
import 'package:defcomm/features/contact/domain/usecases/add_contact.dart';
import 'package:defcomm/features/contact/presentation/bloc/contact_bloc.dart';
import 'package:defcomm/features/group_calling/data/datasources/group_call_remote_data_source.dart';
import 'package:defcomm/features/group_calling/data/repositories/group_call_repository_impl.dart';
import 'package:defcomm/features/group_calling/domain/repositories/group_call_repository.dart';
import 'package:defcomm/features/group_calling/domain/usecase/start_group_call.dart';
import 'package:defcomm/features/group_calling/presentation/bloc/group_call_bloc.dart';
import 'package:defcomm/features/group_calling/presentation/bloc/group_call_events.dart';
import 'package:defcomm/features/group_chat/data/datasources/group_chat_local_data_source.dart';
import 'package:defcomm/features/group_chat/data/datasources/group_chat_remote_data_source.dart';
import 'package:defcomm/features/group_chat/data/repositories/group_chat_repository_impl.dart';
import 'package:defcomm/features/group_chat/domain/repositories/group_chat_repository.dart';
import 'package:defcomm/features/group_chat/domain/usecases/fetch_group_messages.dart';
import 'package:defcomm/features/group_chat/domain/usecases/fetch_local_group_messages.dart';
import 'package:defcomm/features/group_chat/domain/usecases/send_group_message.dart';
import 'package:defcomm/features/group_chat/presentation/bloc/group_chat_bloc.dart';
import 'package:defcomm/features/group_non_contacts/data/datasources/unknown_members_remote_data_source.dart';
import 'package:defcomm/features/group_non_contacts/data/repositories/unknown_members_repository_impl.dart';
import 'package:defcomm/features/group_non_contacts/domain/repoitories/unknown_members_repository.dart';
import 'package:defcomm/features/group_non_contacts/domain/usecases/get_unknown_members.dart';
import 'package:defcomm/features/group_non_contacts/presentation/blocs/unknown_members_bloc.dart';
import 'package:defcomm/features/groups/data/datsources/group_remote_data_source.dart';
import 'package:defcomm/features/groups/data/repositories/group_repository_impl.dart';
import 'package:defcomm/features/groups/domain/repositories/group_repository.dart';
import 'package:defcomm/features/groups/domain/usecases/accept_invitation.dart';
import 'package:defcomm/features/groups/domain/usecases/decline_invitation.dart';
import 'package:defcomm/features/groups/domain/usecases/get_group.dart';
import 'package:defcomm/features/groups/domain/usecases/get_group_members.dart';
import 'package:defcomm/features/groups/domain/usecases/get_pending_groups.dart';
import 'package:defcomm/features/groups/presentation/bloc/group_bloc.dart';
import 'package:defcomm/features/groups/presentation/bloc/group_member_bloc.dart';
import 'package:defcomm/features/linked_devices/data/datasources/linked_device_datasource.dart';
import 'package:defcomm/features/linked_devices/data/datasources/linked_devices_remote_datasource.dart';
import 'package:defcomm/features/linked_devices/data/repositories/linked_devices_repository_impl.dart' hide LinkedDevicesRemoteDataSource;
import 'package:defcomm/features/linked_devices/domain/repositories/linked_devices_repository.dart';
import 'package:defcomm/features/linked_devices/domain/usecase/get_linked_devices.dart';
import 'package:defcomm/features/linked_devices/presenation/blocs/linked_devices_bloc.dart';
import 'package:defcomm/features/messaging/data/datasources/messaging_local_datasource.dart';
import 'package:defcomm/features/messaging/data/datasources/messaging_remote_data_source_impl.dart';
import 'package:defcomm/features/messaging/data/datasources/messaging_remote_datasource.dart';
import 'package:defcomm/features/messaging/data/repositories/messaging_repository_impl.dart';
import 'package:defcomm/features/messaging/domain/repositories/messaging_repositories.dart';
import 'package:defcomm/features/messaging/domain/usecases/fetch_message_threads.dart';
import 'package:defcomm/features/messaging/domain/usecases/fetch_stories.dart';
import 'package:defcomm/features/messaging/domain/usecases/get_cached_groups.dart';
import 'package:defcomm/features/messaging/domain/usecases/get_cached_message_threads.dart';
import 'package:defcomm/features/messaging/domain/usecases/get_cached_stories.dart';
import 'package:defcomm/features/messaging/domain/usecases/get_message_groups.dart';
import 'package:defcomm/features/messaging/presentation/bloc/messaging_bloc.dart';
import 'package:defcomm/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:defcomm/features/qr/data/datasources/qr_remote_datasource.dart';
import 'package:defcomm/features/qr/data/repositories/qr_repository_impl.dart';
import 'package:defcomm/features/qr/domain/repositories/qr_repository.dart';
import 'package:defcomm/features/qr/domain/usecases/approve_qr_device.dart';
import 'package:defcomm/features/qr/domain/usecases/get_qr_status.dart';
import 'package:defcomm/features/qr/presentation/bloc/qr_approval_bloc.dart';
import 'package:defcomm/features/recent_calls/data/datasources/call_remote_datasource.dart';
import 'package:defcomm/features/recent_calls/data/datasources/calls_local_data_source.dart';
import 'package:defcomm/features/recent_calls/data/repositories/call_repository_impl.dart';
import 'package:defcomm/features/recent_calls/domain/usecases/get_local_calls.dart';
import 'package:defcomm/features/recent_calls/domain/usecases/get_recent_calls.dart';
import 'package:defcomm/features/recent_calls/presentation/cubit/calls_cubit.dart';
import 'package:defcomm/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:defcomm/features/signin/data/datasources/auth_remote_data_source.dart';
import 'package:defcomm/features/signin/data/datasources/auth_remote_data_source_impl.dart';
import 'package:defcomm/features/signin/data/repositories/auth_repository_impl.dart';
import 'package:defcomm/features/signin/domain/repositories/auth_repository.dart';
import 'package:defcomm/features/signin/domain/usecases/request_otp.dart';
import 'package:defcomm/features/signin/domain/usecases/send_app_config.dart';
import 'package:defcomm/features/signin/domain/usecases/verify_otp.dart';
import 'package:defcomm/features/signin/presentation/bloc/auth_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

final serviceLocator = GetIt.instance;

void initDependencies() {

  serviceLocator.registerLazySingleton<SecurityReporter>(
  () => SecurityReporter(
    
  ),
);


  // AUTH
  // BLoC
  serviceLocator.registerFactory(
    () => AuthBloc(requestOtp: serviceLocator(), verifyOtp: serviceLocator(), sendAppConfig: serviceLocator(),),
  );

  // Use cases
  serviceLocator.registerLazySingleton(() => RequestOtp(serviceLocator()));
  serviceLocator.registerLazySingleton(() => VerifyOtp(serviceLocator()));
  serviceLocator.registerLazySingleton(() => SendAppConfig(serviceLocator()));

  // Repository
  serviceLocator.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(serviceLocator(), serviceLocator()),
  );

  // Data Sources
  serviceLocator.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(serviceLocator()),
  );

  // --- Messaging Feature ---
  // BLoC
  serviceLocator.registerLazySingleton(
    () => MessagingBloc(
      fetchStories: serviceLocator(),
      fetchMessageThreads: serviceLocator(),
      getJoinedGroups: serviceLocator(),
      getCachedStories: serviceLocator(),
      getCachedThreads: serviceLocator(),
      getCachedGroups: serviceLocator(),
    ),
  );

  // Use Case
  serviceLocator.registerLazySingleton(() => FetchStories(serviceLocator()));
  serviceLocator.registerLazySingleton(
    () => FetchMessageThreads(serviceLocator()),
  );
  serviceLocator.registerLazySingleton(
    () => GetMessageJoinedGroups(serviceLocator()),
  );

  serviceLocator.registerLazySingleton<MessagingLocalDataSource>(
    () => MessagingLocalDataSourceImpl(),
  );

  // Repository
  serviceLocator.registerLazySingleton<MessagingRepository>(
    () => MessagingRepositoryImpl(
      serviceLocator(),
      serviceLocator(), // Add this
    ),
  );

  // Data Source
  serviceLocator.registerLazySingleton<MessagingRemoteDataSource>(
    () => MessagingRemoteDataSourceImpl(serviceLocator()),
  );


  //  Chat Detail Feature
  
serviceLocator.registerLazySingleton<ChatDetailLocalDataSource>(
  () => ChatDetailLocalDataSourceImpl(GetStorage()),
);

// 2. Data Source (Remote)
serviceLocator.registerLazySingleton<ChatDetailRemoteDataSource>(
  () => ChatDetailRemoteDataSourceImpl(serviceLocator()),
);

serviceLocator.registerLazySingleton<ChatDetailRepository>(
  () => ChatDetailRepositoryImpl(
    serviceLocator<ChatDetailRemoteDataSource>(), 
    serviceLocator<ChatDetailLocalDataSource>(), 
  ),
);

serviceLocator.registerLazySingleton(() => FetchMessages(serviceLocator()));
serviceLocator.registerLazySingleton(() => SendMessage(serviceLocator()));

serviceLocator.registerLazySingleton(() => FetchLocalMessages(serviceLocator()));

serviceLocator.registerLazySingleton(() => GetCachedStories(serviceLocator()));
serviceLocator.registerLazySingleton(() => GetCachedMessageThreads(serviceLocator()));
serviceLocator.registerLazySingleton(() => GetCachedGroups(serviceLocator()));

serviceLocator.registerLazySingleton(
  () => ChatDetailBloc(
    fetchMessages: serviceLocator(),
    sendMessage: serviceLocator(),
    fetchLocalMessages: serviceLocator(), 
  ),
);

  // GROUPS FEATURE
  // ==

  serviceLocator.registerFactory(
    () => GroupBloc(
      getJoinedGroups: serviceLocator(),
      getPendingGroups: serviceLocator(),
      acceptInvitation: serviceLocator(),
      declineInvitation: serviceLocator(), getCachedGroups: serviceLocator(),
    ),
  );

  serviceLocator.registerLazySingleton(() => GetJoinedGroups(serviceLocator()));
  serviceLocator.registerLazySingleton(
    () => GetPendingGroups(serviceLocator()),
  );
  serviceLocator.registerLazySingleton(
    () => AcceptInvitation(serviceLocator()),
  );
  serviceLocator.registerLazySingleton(
    () => DeclineInvitation(serviceLocator()),
  );

  serviceLocator.registerLazySingleton<GroupRepository>(
    () => GroupRepositoryImpl(remoteDataSource: serviceLocator()),
  );

  serviceLocator.registerLazySingleton<GroupRemoteDataSource>(
    () => GroupRemoteDataSourceImpl(client: serviceLocator()),
  );

  // Repository impl
  // serviceLocator.registerLazySingleton<GroupRepository>(
  //   () => GroupRepositoryImpl(remoteDataSource: serviceLocator()),
  // );

  serviceLocator.registerLazySingleton(() => GetGroupMembers(serviceLocator()));

  serviceLocator.registerFactory(
    () => GroupMembersBloc(getGroupMembers: serviceLocator()),
  );

  serviceLocator.registerLazySingleton<ContactRemoteDataSource>(
    () => ContactRemoteDataSourceImpl(client: serviceLocator()),
  );

  serviceLocator.registerLazySingleton<ContactRepository>(
    () => ContactRepositoryImpl(remoteDataSource: serviceLocator()),
  );

  serviceLocator.registerLazySingleton(() => AddContact(serviceLocator()));

  serviceLocator.registerFactory(
    () => ContactBloc(addContactUseCase: serviceLocator()),
  );

  serviceLocator.registerLazySingleton<LocalNotificationService>(
    () => LocalNotificationService(),
  );

  // External
  serviceLocator.registerLazySingleton(() => http.Client());

  // Core Services
  serviceLocator.registerLazySingleton<StorageService>(
    () => StorageServiceImpl(),
  );
  

  // Group chat
  
  //data source
  serviceLocator.registerLazySingleton<GroupChatRemoteDataSource>(
    () => GroupChatRemoteDataSourceImpl(client: serviceLocator<http.Client>()),
  );

  // local datasorce: 

  serviceLocator.registerLazySingleton<GroupChatLocalDataSource>(
  () => GroupChatLocalDataSourceImpl(),
);

  // Group chat: repository
  serviceLocator.registerLazySingleton<GroupChatRepository>(
    () => GroupChatRepositoryImpl(serviceLocator(),  serviceLocator(),),
  );

  // Group chat: use case
  serviceLocator.registerLazySingleton(
    () => FetchGroupMessages(serviceLocator()),
  );
  serviceLocator.registerLazySingleton(
    () => SendGroupMessage(serviceLocator()),
  );
  serviceLocator.registerLazySingleton(
    () => FetchLocalGroupMessages(serviceLocator()),
  );

  // Group chat: BLoC
  serviceLocator.registerLazySingleton(
    () => GroupChatBloc(
      fetchGroupMessages: serviceLocator(),
      sendGroupMessage: serviceLocator(),
      fetchLocalGroupMessages: serviceLocator(),
    ),
  );



  //      Calling feature

  // Remote data source
  serviceLocator.registerLazySingleton<CallRemoteDataSource>(
    () => CallRemoteDataSourceImpl(client: http.Client()),
  );

  // Repository
  serviceLocator.registerLazySingleton<CallRepository>(
    () => CallRepositoryImpl(
      remoteDataSource: serviceLocator<CallRemoteDataSource>(),
    ),
  );

  // Use case
  serviceLocator.registerLazySingleton<StartCall>(
    () => StartCall(serviceLocator<CallRepository>()),
  );

  // Bloc
  serviceLocator.registerLazySingleton<CallBloc>(
    () => CallBloc(startCall: serviceLocator<StartCall>()),
  );

  serviceLocator.registerLazySingleton<CallManager>(() => CallManager());

  // group call
  //   serviceLocator.registerLazySingleton<GroupCallRemoteDataSource>(() =>
  //   GroupCallRemoteDataSourceImpl(client: serviceLocator(), ));
  // serviceLocator.registerLazySingleton<GroupCallRepository>(() =>
  //   GroupCallRepositoryImpl(remote: serviceLocator(), sendGroupMessageUseCase: serviceLocator<SendGroupMessage>(), startCallUsecase:))
  //
  // ;

  // 1) Remote data source - pass your dev token
  serviceLocator.registerLazySingleton<GroupCallRemoteDataSource>(
    () => GroupCallRemoteDataSourceImpl(
      client:
          serviceLocator<
            http.Client
          >(), 
    ),
  );

  // 2) Repository impl - pass SendGroupMessage and StartCall usecases
  serviceLocator.registerLazySingleton<GroupCallRepository>(
    () => GroupCallRepositoryImpl(
      remote: serviceLocator<GroupCallRemoteDataSource>(),
      sendGroupMessageUseCase: serviceLocator<SendGroupMessage>(),
      startCallUsecase: serviceLocator<StartCall>(),
    ),
  );

  // usecase & bloc
  serviceLocator.registerFactory(
    () => StartGroupCall(serviceLocator<GroupCallRepository>()),
  );
  serviceLocator.registerFactory(
    () => GroupCallBloc(
      startGroupCall: serviceLocator<StartGroupCall>(),
      repository: serviceLocator<GroupCallRepository>(),
      callManager: serviceLocator<CallManager>(),
      currentUserId: '',
    ),
  );

  
  serviceLocator.registerLazySingleton<CallsRemoteDataSource>(
    () => CallsRemoteDataSourceImpl(client: serviceLocator<http.Client>()),
  );

  
  serviceLocator.registerLazySingleton<CallsRepository>(
    () => CallsRepositoryImpl(remote: serviceLocator<CallsRemoteDataSource>(), local: serviceLocator(),),
  );
  serviceLocator.registerLazySingleton<CallsLocalDataSource>(
  () => CallsLocalDataSourceImpl(GetStorage()),
);

  // 3) Use case
  serviceLocator.registerLazySingleton(
    () => GetRecentCalls(serviceLocator<CallsRepository>()),
  );
  serviceLocator.registerLazySingleton(
  () => GetLocalCalls(serviceLocator()),
);

  serviceLocator.registerLazySingleton(
    () => CallsCubit(getRecentCalls: serviceLocator<GetRecentCalls>(), getLocalCalls: serviceLocator(),),
  );

  serviceLocator.registerLazySingleton(() => SettingsBloc());

serviceLocator.registerLazySingleton(() => ProfileBloc());


// linked devices
// Data source
// --- Linked Devices Feature ---

// 1. Data Sources
serviceLocator.registerLazySingleton<LinkedDevicesLocalDataSource>(
  // Ensure you import the Implementation we wrote in the previous step
  () => LinkedDevicesLocalDataSourceImpl(serviceLocator()), 
);

serviceLocator.registerLazySingleton<LinkedDevicesRemoteDataSource>(
  () => LinkedDevicesRemoteDataSourceImpl(
    serviceLocator(), 
  ),
);

serviceLocator.registerLazySingleton<LinkedDevicesRepository>(
  () => LinkedDevicesRepositoryImpl(
    remoteDataSource: serviceLocator(),
    localDataSource: serviceLocator(),
  ),
);

serviceLocator.registerLazySingleton(
  () => GetLinkedDevices(serviceLocator()),
);

serviceLocator.registerFactory<LinkedDevicesBloc>(
  () {
    final localDataSource = serviceLocator<LinkedDevicesLocalDataSource>();
    
    final cachedDevices = localDataSource.getLastDevicesSync();

    return LinkedDevicesBloc(
      serviceLocator(),
      initialDevices: cachedDevices, 
    );
  },
);

  serviceLocator.registerLazySingleton<UnknownMembersRemoteDataSource>(
    () => UnknownMembersRemoteDataSourceImpl(serviceLocator()), 
  );

  serviceLocator.registerLazySingleton<UnknownMembersRepository>(
    () => UnknownMembersRepositoryImpl(serviceLocator()),
  );

  serviceLocator.registerLazySingleton(
    () => GetUnknownMembers(serviceLocator()),
  );

  serviceLocator.registerFactory(
    () => UnknownMembersBloc(getUnknownMembers: serviceLocator()),
  );


//  QR DATA SOURCE 
serviceLocator.registerLazySingleton<QrRemoteDataSource>(
  () => QrRemoteDataSourceImpl(
    client: serviceLocator<http.Client>(),
  ),
);

//  QR REPOSITORY 
serviceLocator.registerLazySingleton<QrRepository>(
  () => QrRepositoryImpl(
    serviceLocator<QrRemoteDataSource>(),
  ),
);

//  QR USE CASES 
serviceLocator.registerLazySingleton(
  () => GetQrStatus(
    serviceLocator<QrRepository>(),
  ),
);

serviceLocator.registerLazySingleton(
  () => ApproveQrDevice(
    serviceLocator<QrRepository>(),
  ),
);

//  QR BLOC 
serviceLocator.registerFactory(
  () => QrApprovalBloc(
    serviceLocator<GetQrStatus>(),
    serviceLocator<ApproveQrDevice>(),
  ),
);

 serviceLocator.registerLazySingleton(() => GetStorage()); 



}
