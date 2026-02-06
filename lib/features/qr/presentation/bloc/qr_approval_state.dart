// presentation/bloc/qr_approval_state.dart
import 'package:equatable/equatable.dart';
import '../../domain/entities/qr_session.dart';

abstract class QrApprovalState extends Equatable {
  const QrApprovalState();
  @override
  List<Object?> get props => [];
}

class QrInitial extends QrApprovalState {}

class QrLoading extends QrApprovalState {}

class QrReady extends QrApprovalState {
  final QrSession session;
  const QrReady(this.session);

  @override
  List<Object?> get props => [session];
}

class QrApproved extends QrApprovalState {}

class QrExpired extends QrApprovalState {}

class QrError extends QrApprovalState {
  final String message;
  const QrError(this.message);

  @override
  List<Object?> get props => [message];
}
