import 'package:equatable/equatable.dart';

class QrSession extends Equatable {
  final String id;
  final QrStatus status;
  final String? deviceName;

  const QrSession({
    required this.id,
    required this.status,
    this.deviceName,
  });

  @override
  List<Object?> get props => [id, status, deviceName];
}

enum QrStatus {
  pending,
  approved,
  expired,
}
