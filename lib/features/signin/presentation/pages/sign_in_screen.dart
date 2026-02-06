// ignore_for_file: deprecated_member_use

import 'package:defcomm/core/theme/app_colors.dart';
import 'package:defcomm/features/otp/presentation/pages/otp_screen.dart';
import 'package:defcomm/features/signin/presentation/bloc/auth_bloc.dart';
import 'package:defcomm/features/signin/presentation/bloc/auth_event.dart';
import 'package:defcomm/features/signin/presentation/bloc/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:country_picker/country_picker.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool syncContacts = true;
  Country? _selectedCountry;
  final TextEditingController _phoneController = TextEditingController();

  void _openCountryPicker() {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      onSelect: (Country country) {
        setState(() {
          _selectedCountry = country;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final flag = _selectedCountry?.flagEmoji ?? '🇳🇬';
    final dialCode = _selectedCountry?.phoneCode ?? '234';
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(gradient: AppColors.appGradientColor2),
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Image.asset(
                'images/signin_background.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: 250,
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
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(flex: 3),

                    Padding(
                      padding: const EdgeInsets.only(left: 50),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sign in',
                            style: GoogleFonts.poppins(
                              fontSize: 25,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'With Defcomm Credentials',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 30),

                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.05,
                        vertical: screenHeight * 0.002,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.phoneInputGreenBorder,
                        ),
                        color: AppColors.phoneInputGreen,
                      ),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: _openCountryPicker,
                            borderRadius: BorderRadius.circular(10),
                            child: Row(
                              children: [
                                ClipOval(
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    color: Colors.white.withOpacity(0.1),
                                    alignment: Alignment.center,
                                    child: Text(
                                      flag,
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '+$dialCode',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    color: Colors.white,
                                  ),
                                ),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Colors.white70,
                                  size: 22,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Mobile number',
                                hintStyle: GoogleFonts.inter(
                                  color: Colors.white.withOpacity(0.6),
                                ),
                                counterText: '',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 2),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Sync Contacts',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Switch(
                            value: syncContacts,
                            onChanged: (val) {
                              setState(() {
                                syncContacts = val;
                              });
                            },
                            activeThumbColor: AppColors.primaryGradientStart,
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 3),

                    Center(
                      child: Column(
                        children: [
                          BlocConsumer<AuthBloc, AuthState>(
                            listener: (context, state) {
                              if (state is AuthFailure) {
                                debugPrint(
                                  "mfailure message: ${state.message}",
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(state.message),
                                    backgroundColor: AppColors.tertiaryGreen,
                                  ),
                                );
                              }
                              if (state is OtpRequestSuccess) {
                                debugPrint("${state.otpResponse.message}");
                                debugPrint("dialCode: $dialCode");
                                debugPrint("phone number: ${_phoneController.text.trim()}");
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OtpScreen(
                                      phoneNumber: _phoneController.text.trim(),
                                      dialCode: dialCode
                                    ),
                                  ),
                                );
                              }
                            },
                            builder: (context, state) {
                              if (state is AuthLoading) {
                                return Center(
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: AppColors.tertiaryGreen
                                          .withOpacity(0.7),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return GestureDetector(
                                onTap: () {
                                  FocusScope.of(context).unfocus();
                                  final fullPhoneNumber =
                                      '+$dialCode${_phoneController.text.trim()}';
                                  debugPrint("phone_number: $fullPhoneNumber");
                                  context.read<AuthBloc>().add(
                                    AuthRequestOtp(phone: fullPhoneNumber),
                                  );
                                },
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: AppColors.tertiaryGreen.withOpacity(
                                      0.7,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 12),
                          Text(
                            'Use online instead of local account...',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.secondaryWhite,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
