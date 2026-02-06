import '../entities/qr_session.dart';
import '../repositories/qr_repository.dart';

class GetQrStatus {
  final QrRepository repository;

  GetQrStatus(this.repository);

  Future<QrSession> call(String qrId) {
    return repository.getQrStatus(qrId);
  }
}
