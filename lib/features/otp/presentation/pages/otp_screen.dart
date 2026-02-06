import 'dart:async';
import 'package:defcomm/core/theme/app_colors.dart';
import 'package:defcomm/features/account_setup/presentation/pages/account_setup_screen.dart';
import 'package:defcomm/features/signin/presentation/bloc/auth_bloc.dart';
import 'package:defcomm/features/signin/presentation/bloc/auth_event.dart';
import 'package:defcomm/features/signin/presentation/bloc/auth_state.dart';
import 'package:defcomm/init_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.phoneNumber, this.dialCode});
  final String phoneNumber;
  final String? dialCode;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  late Timer _timer;
  int _start = 30;

  final _pinController = TextEditingController();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    _start = 30; 
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          timer.cancel();
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    

    final defaultPinTheme = PinTheme(
      width: screenWidth * 0.9,
      height: screenHeight * 0.14,
      textStyle: GoogleFonts.poppins(fontSize: 22, color: Colors.white),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondaryGreen, width: 1.5),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: AppColors.secondaryGreen, width: 2.5),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: AppColors.secondaryGreen, width: 2.5),
      ),
    );

    final errorPinTheme = PinTheme(
    width: screenWidth * 0.9,
    height: screenHeight * 0.14,
    textStyle: GoogleFonts.poppins(fontSize: 22, color: Colors.white),
    decoration: BoxDecoration(
      color: Colors.red.withOpacity(0.1), 
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.red, width: 1.5), 
    ),
  );

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
      if (state is AuthFailure) {
        setState(() {
          _errorMessage = state.message;
        });
      }
      if (state is AuthVerifySuccess) {

        
              Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (BuildContext context) => const AccountSetupScreen(),
          ),
        );
      }
    },
    builder: (context, state) {
      final bool showError = state is AuthFailure && _errorMessage != null;
      return GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          body: Container(
            decoration: BoxDecoration(gradient: AppColors.appGradientColor2),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.appGradientColor2,
                  ),
                ),

                Align(
                  alignment: Alignment.topRight,
                  child: SafeArea(
                    child: Image.asset(
                      "images/defcomm_logo_1.png",
                      height: 50,
                      width: 50,
                    ),
                  ),
                ),
                SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(height: screenHeight * 0.1),
                    
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.09,
                          ),
                          child: Column(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Verify OTP",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 25,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Use PIN to unlock fast and\nsecure way",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white.withOpacity(0.7),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 15,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: screenHeight * 0.1),
                          
                              Pinput(
                                length: 4,
                                defaultPinTheme: defaultPinTheme,
                                errorPinTheme: errorPinTheme,
                                focusedPinTheme: defaultPinTheme.copyWith(
                                  decoration: defaultPinTheme.decoration!
                                      .copyWith(
                                        border: Border.all(
                                          color: AppColors.secondaryGreen,
                                          width: 2,
                                        ),
                                      ),
                                ),
                                 forceErrorState: showError, 
                                  onChanged: (pin) {
                              if (_errorMessage != null) {
                                setState(() {
                                  _errorMessage = null;
                                });
                              }
                            },
                                onCompleted: (pin) {
                                  FocusScope.of(context).unfocus();
                                  context.read<AuthBloc>().add(
                                    AuthVerifyOtp(
                                      phone: "+${widget.dialCode ?? ""}${widget.phoneNumber}",
                                      otp: pin,
                                    ),
                                  );
                                  debugPrint('Completed: $pin');
                                  debugPrint('number: ${widget.phoneNumber}');
                                },
                              ),
                          
                              AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _errorMessage != null
                                ? Padding(
                                    key: const ValueKey('error'),
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      _errorMessage!,
                                      style: GoogleFonts.poppins(color: Colors.red, fontSize: 14),
                                    ),
                                  )
                                : const SizedBox(key: ValueKey('no-error'), height: 22), 
                          ),
                          
                          const SizedBox(height: 20),
                              const SizedBox(height: 30),
                          
                              GestureDetector(
                                onTap: () {
                                  if (_start == 0) {
                                    context.read<AuthBloc>().add(
                                      AuthRequestOtp(phone: widget.phoneNumber),
                                    );
                                    startTimer(); 
                                  }
                                },
                                child: Text(
                                  _start > 0
                                      ? 'Send code again 00:${_start.toString().padLeft(2, '0')}'
                                      : 'Resend Code',
                                  style: GoogleFonts.poppins(
                                    color: _start > 0
                                        ? Colors.white.withOpacity(0.5)
                                        : AppColors.secondaryGreen,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                          
                                BlocBuilder<AuthBloc, AuthState>(
                                    builder: (context, state) {
                                      if (state is AuthLoading) {
                                        return const Center(child: CircularProgressIndicator());
                                      }
                                      return const SizedBox.shrink(); 
                                    },
                                  )
                            ],
                          ),
                        ),
                        // const Spacer(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }, 
    );
  }
}
