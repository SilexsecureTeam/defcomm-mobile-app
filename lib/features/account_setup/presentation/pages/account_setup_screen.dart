import 'dart:async';
import 'package:defcomm/core/theme/app_colors.dart';
import 'package:defcomm/features/app_navigation/presentation/pages/home_navr.dart';
import 'package:defcomm/features/home/presentation/pages/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/animated_checklist_item.dart'; 


class AccountSetupScreen extends StatefulWidget {
  const AccountSetupScreen({super.key});

  @override
  State<AccountSetupScreen> createState() => _AccountSetupScreenState();
}

class _AccountSetupScreenState extends State<AccountSetupScreen> {
  double _progress = 0.0;
  bool _navigationScheduled = false;

  @override
  void initState() {
    super.initState();
    _startSetupProcess();
  }

  void _startSetupProcess() {
    Timer.periodic(const Duration(milliseconds: 25), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _progress += 0.01;
        if (_progress >= 1.0) _progress = 1.0;
      });
      if (_progress >= 1.0 && !_navigationScheduled) {
        _navigationScheduled = true;
        timer.cancel();
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          FocusScope.of(context).unfocus();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (BuildContext context) => const HomeNavr(),
            ),
          );
          print("Setup complete! Navigating to home...");
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {


    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(minHeight: screenHeight),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryGradientStart, Colors.black],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.7],
            ),
            
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // const Spacer(flex: 2),
                SizedBox(height: screenHeight * 0.05),
            
                Image.asset(
                  'images/defcomm_logo_1.png',
                  width: 100,
                  height: 100,
                  color: Colors.white, 
                ),
                const SizedBox(height: 40),
            
                Text(
                  'Setting Up Account...',
                  style: GoogleFonts.poppins(
                    color: AppColors.settingAccountGreen,
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Do not close this page',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 30),
            
                Padding(
                  padding:  EdgeInsets.symmetric(horizontal: screenWidth * 0.09),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 8,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor:
                           AlwaysStoppedAnimation<Color>(Colors.grey),
                    ),
                  ),
                ),
                 SizedBox(height: 50),
            
                Padding(
                  padding:  EdgeInsets.symmetric(horizontal: screenWidth * 0.09),
                  child: Column(
                    children:  [
                      AnimatedChecklistItem(
                        text: 'Authenticate users with OTP or certificates',
                        delay: Duration(milliseconds: 500),
                      ),
                      AnimatedChecklistItem(
                        text: 'Restrict access to authorized devices only',
                        delay: Duration(milliseconds: 1000),
                      ),
                      AnimatedChecklistItem(
                        text: 'Establishing encrypted connections',
                        delay: Duration(milliseconds: 1500),
                      ),
                    ],
                  ),
                ),
            
                //  Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}