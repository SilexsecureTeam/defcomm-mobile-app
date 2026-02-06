import 'package:defcomm/core/theme/app_colors.dart';
import 'package:defcomm/features/qr/presentation/bloc/qr_approval_bloc.dart';
import 'package:defcomm/features/qr/presentation/bloc/qr_approval_event.dart';
import 'package:defcomm/features/qr/presentation/bloc/qr_approval_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class QrApprovalScreen extends StatelessWidget {
  const QrApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<QrApprovalBloc, QrApprovalState>(
      listener: (context, state) {
        if (state is QrApproved) {
  Future.delayed(const Duration(seconds: 2), () {
    if (context.mounted) {
      Navigator.pop(context, 'approved'); 
    }
  });
}
      },
      child: Scaffold(
        backgroundColor: AppColors.tertiaryGreen,
        appBar: AppBar(
          title: const Text('Approve Login'),
          automaticallyImplyLeading: true, 
        ),
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.dashboardBackgroundColor,
              ),
            ),
            BlocBuilder<QrApprovalBloc, QrApprovalState>(
              builder: (context, state) {
                if (state is QrLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is QrReady) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.desktop_windows, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Approve login?',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[300],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Device: ${state.session.deviceName ?? 'Unknown device'}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[300],
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              context.read<QrApprovalBloc>().add(
                                    QrApprovePressed(state.session.id),
                                  );
                            },
                            child: const Text('Approve'),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (state is QrApproved) {
                  return  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 64, color: Colors.grey[300]),
                        SizedBox(height: 16),
                        Text(
                          'Device approved successfully',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  );
                }

                if (state is QrExpired) {
                  return const Center(child: Text('QR code has expired'));
                }

                if (state is QrError) {
                  return Center(
                    child: Text(
                      state.message, 
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}