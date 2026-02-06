import 'package:defcomm/features/settings/domain/entities/shield_settings.dart';
import 'package:equatable/equatable.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object> get props => [];
}

class ToggleHideMessages extends SettingsEvent {
  final bool isEnabled;
  const ToggleHideMessages(this.isEnabled);

  @override
  List<Object> get props => [isEnabled];
}

class TogglePushNotifications extends SettingsEvent {
  final bool isEnabled;
  const TogglePushNotifications(this.isEnabled);

  @override
  List<Object> get props => [isEnabled];
}

class ChangeShieldRevealMethod extends SettingsEvent {
  final ShieldRevealMethod method;
  const ChangeShieldRevealMethod(this.method);

  @override
  List<Object> get props => [method];
}