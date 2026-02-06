import '../repositories/qr_repository.dart';

class ApproveQrDevice {
  final QrRepository repository;

  ApproveQrDevice(this.repository);

  Future<void> call(String qrId) {
    return repository.approveQr(qrId);
  }
}