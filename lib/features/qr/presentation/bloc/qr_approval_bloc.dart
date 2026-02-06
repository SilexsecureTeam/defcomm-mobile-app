import 'package:defcomm/features/qr/domain/usecases/approve_qr_device.dart';
import 'package:defcomm/features/qr/domain/usecases/get_qr_status.dart';
import 'package:defcomm/features/qr/presentation/bloc/qr_approval_event.dart';
import 'package:defcomm/features/qr/presentation/bloc/qr_approval_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class QrApprovalBloc extends Bloc<QrApprovalEvent, QrApprovalState> {
  final GetQrStatus getStatus;
  final ApproveQrDevice approve;

  QrApprovalBloc(
    this.getStatus,
    this.approve,
  ) : super(QrInitial()) {
    on<QrScanned>(_onScanned);
    on<QrApprovePressed>(_onApprove);
  }

  Future<void> _onScanned(
    QrScanned event,
    Emitter<QrApprovalState> emit,
  ) async {
    emit(QrLoading());
    try {
      final session = await getStatus(event.qrId);
      if (session.status == 'expired') {
        emit(QrExpired());
      } else {
        emit(QrReady(session));
      }
    } catch (e) {
      emit(const QrError('Invalid or expired QR code'));
    }
  }

  Future<void> _onApprove(
    QrApprovePressed event,
    Emitter<QrApprovalState> emit,
  ) async {
    emit(QrLoading());
    try {
      await approve(event.qrId);
      emit(QrApproved());
    } catch (_) {
      emit(const QrError('Failed to approve device'));
    }
  }
}

