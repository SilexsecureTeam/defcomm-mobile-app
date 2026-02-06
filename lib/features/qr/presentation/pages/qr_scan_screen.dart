import 'package:defcomm/features/qr/presentation/bloc/qr_approval_bloc.dart';
import 'package:defcomm/features/qr/presentation/bloc/qr_approval_event.dart';
import 'package:defcomm/features/qr/presentation/bloc/qr_approval_state.dart';
import 'package:defcomm/features/qr/presentation/pages/qr_approval_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  bool _hasScanned = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<QrApprovalBloc, QrApprovalState>(
      listener: (context, state) async {
        if (state is QrReady) {
          final qrBloc = context.read<QrApprovalBloc>();


          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: qrBloc, 
                child: const QrApprovalScreen(),
              ),
            ),
          );


          debugPrint("Result from approval screen: $result"); 

          if (result == 'approved' && context.mounted) {
            Navigator.pop(context);
          } else {
          }
        }

        if (state is QrExpired) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('QR code expired')));
          _hasScanned = false;
        }

        if (state is QrError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
          _hasScanned = false;
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Scan QR Code')),
        body: MobileScanner(
          onDetect: (capture) {
            if (_hasScanned) return;

            final barcode = capture.barcodes.first;
            final rawValue = barcode.rawValue;

            if (rawValue == null) return;

            try {
              final decoded = jsonDecode(rawValue);

              if (decoded is Map<String, dynamic> &&
                  decoded['type'] == 'qr-login' &&
                  decoded['code'] != null) {
                final qrId = decoded['code'] as String;

                _hasScanned = true;

                context.read<QrApprovalBloc>().add(QrScanned(qrId));
              } else {
                throw const FormatException('Invalid QR format');
              }
            } catch (e) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Invalid QR code')));
            }
          },
        ),
      ),
    );
  }
}
