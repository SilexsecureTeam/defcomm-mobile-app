import 'package:equatable/equatable.dart';

abstract class QrApprovalEvent extends Equatable {
  const QrApprovalEvent();
  @override
  List<Object?> get props => [];
}

class QrScanned extends QrApprovalEvent {
  final String qrId;
  const QrScanned(this.qrId);

  @override
  List<Object?> get props => [qrId];
}

class QrApprovePressed extends QrApprovalEvent {
  final String qrId;
  const QrApprovePressed(this.qrId);

  @override
  List<Object?> get props => [qrId];
}
