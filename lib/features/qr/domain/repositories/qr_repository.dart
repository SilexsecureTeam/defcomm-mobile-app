import '../entities/qr_session.dart';

abstract class QrRepository {
  Future<QrSession> getQrStatus(String qrId);
  Future<void> approveQr(String qrId);
}
