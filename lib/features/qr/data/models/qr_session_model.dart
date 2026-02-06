import '../../domain/entities/qr_session.dart';

class QrSessionModel extends QrSession {
  const QrSessionModel({
    required super.id,
    required super.status,
    super.deviceName,
  });

  factory QrSessionModel.fromJson(
    Map<String, dynamic> json,
    String qrId,
  ) {
    return QrSessionModel(
      id: qrId,
      status: _mapStatus(json['status']),
      deviceName: json['device_name'],
    );
  }

  static QrStatus _mapStatus(String status) {
    switch (status) {
      case 'approved':
        return QrStatus.approved;
      case 'expired':
        return QrStatus.expired;
      default:
        return QrStatus.pending;
    }
  }
}
