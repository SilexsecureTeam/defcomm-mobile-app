// data/repositories/qr_repository_impl.dart
import '../../domain/entities/qr_session.dart';
import '../../domain/repositories/qr_repository.dart';
import '../datasources/qr_remote_datasource.dart';

class QrRepositoryImpl implements QrRepository {
  final QrRemoteDataSource remote;

  QrRepositoryImpl(this.remote);

  @override
  Future<QrSession> getQrStatus(String qrId) {
    return remote.getStatus(qrId);
  }

  @override
  Future<void> approveQr(String qrId) {
    return remote.approve(qrId);
  }
}
