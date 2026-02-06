import 'dart:async';
import 'dart:math'; // For pi
import 'package:defcomm/core/theme/app_colors.dart';
import 'package:defcomm/features/onboarding/presentation/pages/onboarding_screen.dart';
import 'package:defcomm/features/splash/presentation/widgest/gradient_circular_progress_indicator.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum SplashStage {
  initial,      
  redefining,   
  walkieTalkie, 
}

class UnifiedSplashScreen extends StatefulWidget {
  const UnifiedSplashScreen({Key? key}) : super(key: key);

  @override
  State<UnifiedSplashScreen> createState() => _UnifiedSplashScreenState();
}

class _UnifiedSplashScreenState extends State<UnifiedSplashScreen> {
  SplashStage _currentStage = SplashStage.initial;

  @override
  void initState() {
    super.initState();
    _startSplashSequence();
  }

  void _startSplashSequence() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      setState(() {
        _currentStage = SplashStage.redefining;
      });
    }

    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      setState(() {
        _currentStage = SplashStage.walkieTalkie;
      });
    }

    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'images/US_army_soldier-3.jpg.png',
            fit: BoxFit.cover,
          ),
          Container(
            decoration:  BoxDecoration(
              gradient: AppColors.appGradientOverlay,
            ),
          ),
          Positioned(
            left: 20,
            child: SafeArea(child: Image.asset("images/nigeria_img.png")),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 700), 
            child: _buildStageContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildStageContent() {
    switch (_currentStage) {
      case SplashStage.initial:
        return const SizedBox(key: ValueKey('initial'));

      case SplashStage.redefining:
        return Padding(
          key: const ValueKey('redefining'), // Unique key for this stage
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Spacer(),
               Center(
                child: SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(
            strokeWidth: 6,
            valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF91C83E)),
            backgroundColor: Colors.white.withOpacity(0.2),
          ),
        ),
                
               
              ),
              const SizedBox(height: 40),
              Text(
                'Redefining Defence',
                style: GoogleFonts.almarai(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, height: 1.2),
              ),
              Text(
                'Communication',
                style: GoogleFonts.almarai(
                  color: AppColors.primaryGradientStart,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: AppColors.primaryGradientStart,
                  decorationThickness: 2.0,
                ),
              ),
            ],
          ),
        );

      case SplashStage.walkieTalkie:
        return Padding(
          key: const ValueKey('walkieTalkie'), // Unique key for this stage
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            children: [
              const Spacer(),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(
                    color: AppColors.walkieRed,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: ClipRRect(
                    child: Image.asset("images/walkie.png", height: 90, width: 40),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Redefining Defence',
                style: GoogleFonts.almarai(color: Colors.transparent, fontSize: 20, fontWeight: FontWeight.bold, height: 1.2),
              ),
              Text(
                'Communication',
                style: GoogleFonts.almarai(
                  color: Colors.transparent,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                  decoration: TextDecoration.lineThrough,
                  decorationThickness: 2.0,
                ),
              ),
            ],
          ),
        );
    }
  }
}