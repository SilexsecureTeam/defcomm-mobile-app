import 'package:defcomm/features/settings/domain/entities/shield_settings.dart';
import 'package:equatable/equatable.dart';

class SettingsState extends Equatable {
  final bool hideMessages;
  final bool pushNotifications;
    final ShieldRevealMethod shieldRevealMethod;

  const SettingsState({
    this.hideMessages = true,
    this.pushNotifications = true,
    this.shieldRevealMethod = ShieldRevealMethod.longPress,
  });

  SettingsState copyWith({
    bool? hideMessages,
    bool? pushNotifications,
    ShieldRevealMethod? shieldRevealMethod,
  }) {
    return SettingsState(
      hideMessages: hideMessages ?? this.hideMessages,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      shieldRevealMethod: shieldRevealMethod ?? this.shieldRevealMethod,
    );
  }

  @override
  List<Object> get props => [hideMessages, pushNotifications, shieldRevealMethod];
}