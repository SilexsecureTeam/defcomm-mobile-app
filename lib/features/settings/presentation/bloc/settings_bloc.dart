import 'package:defcomm/features/settings/domain/entities/shield_settings.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'settings_event.dart';
import 'settings_state.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {

  final _box = GetStorage();
  
  SettingsBloc() : super(const SettingsState()) {

     _checkInitialNotificationStatus();

     _loadSettings();

    on<ToggleHideMessages>((event, emit) {
      _box.write('hideMessages', event.isEnabled);
      emit(state.copyWith(hideMessages: event.isEnabled));
    });

    on<TogglePushNotifications>(_onTogglePushNotifications);

      on<ChangeShieldRevealMethod>((event, emit) {
        _box.write('shieldMethodIndex', event.method.index);
      emit(state.copyWith(shieldRevealMethod: event.method));
    });
    
  }

    Future<void> _loadSettings() async {
    final bool savedHideMessages = _box.read('hideMessages') ?? true;

    final int savedShieldIndex = _box.read('shieldMethodIndex') ?? 1;
    final savedShieldMethod = ShieldRevealMethod.values[savedShieldIndex];
    final bool userPrefersNotifications = _box.read('pushNotifications') ?? true;
    final status = await Permission.notification.status;
        final bool isPushEnabled = userPrefersNotifications && status.isGranted;

    emit(state.copyWith(
      hideMessages: savedHideMessages,
      shieldRevealMethod: savedShieldMethod,
      pushNotifications: isPushEnabled,
    ));
  }

  Future<void> _checkInitialNotificationStatus() async {
    final status = await Permission.notification.status;
    emit(state.copyWith(pushNotifications: status.isGranted));
  }
  
  Future<void> _onTogglePushNotifications(
    TogglePushNotifications event,
    Emitter<SettingsState> emit,
  ) async {
    _box.write('pushNotifications', event.isEnabled);

    if (event.isEnabled) {
      final status = await Permission.notification.status;

      if (status.isGranted) {
        emit(state.copyWith(pushNotifications: true));
      } else if (status.isDenied) {
        final result = await Permission.notification.request();
        emit(state.copyWith(pushNotifications: result.isGranted));
        if (!result.isGranted) _box.write('pushNotifications', false);
      } else if (status.isPermanentlyDenied) {
        await openAppSettings();
        emit(state.copyWith(pushNotifications: false));
      }
    } else {
      emit(state.copyWith(pushNotifications: false));
    }
  }
}


