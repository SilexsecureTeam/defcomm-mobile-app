import 'package:defcomm/features/secure_comms/data/models/otp_details_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:qr_flutter/qr_flutter.dart';

class OtpVerificationContent extends StatelessWidget {
  final OtpDetails otpDetails;

  const OtpVerificationContent({super.key, required this.otpDetails});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      color: Colors.white,
      child: Column(
        children: [
          _buildQrCode(context),
          const SizedBox(height: 24),
          _buildOtpSection(context),
          const SizedBox(height: 32),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildQrCode(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 5,
          )
        ],
      ),
      child: QrImageView(
        data: otpDetails.qrCodeData,
        version: QrVersions.auto,
        size: 150.0,
      ),
    );
  }

  Widget _buildOtpSection(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 56,
      textStyle: GoogleFonts.poppins(fontSize: 22, color: Colors.grey.shade700),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
    );

    return Column(
      children: [
        Text(
          "Verification code",
          style: GoogleFonts.poppins(color: Colors.grey.shade700),
        ),
        const SizedBox(height: 16),
        Pinput(
          length: 6,
          defaultPinTheme: defaultPinTheme,
          focusedPinTheme: defaultPinTheme.copyWith(
            decoration: defaultPinTheme.decoration!.copyWith(
              border: Border.all(color: const Color(0xFF4B5320)),
            ),
          ),
          separatorBuilder: (index) => index == 2
              ? const SizedBox(width: 16, child: Center(child: Text("-")))
              : const SizedBox(width: 8),
        ),
        const SizedBox(height: 16),
        RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(color: Colors.grey.shade600),
            children: [
              const TextSpan(text: "Didn't get a code? "),
              TextSpan(
                text: "Click to resend.",
                style: const TextStyle(decoration: TextDecoration.underline),
                // recognizer: TapGestureRecognizer()..onTap = () { /* Handle resend */ },
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox( /* ... Same Confirm Button as before ... */ ),
        const SizedBox(height: 12),
        SizedBox( /* ... Same Cancel Button as before ... */ ),
      ],
    );
  }
}