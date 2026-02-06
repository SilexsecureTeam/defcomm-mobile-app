import 'dart:async';
import 'dart:math';

import 'package:defcomm/core/theme/app_colors.dart';
import 'package:defcomm/features/splash/presentation/pages/splash_screen_3.dart';
import 'package:defcomm/features/splash/presentation/widgest/gradient_circular_progress_indicator.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen2 extends StatefulWidget {
  const SplashScreen2({super.key});

  @override
  State<SplashScreen2> createState() => _SplashScreen2State();
}

class _SplashScreen2State extends State<SplashScreen2> {
  @override
  void initState() {
    super.initState();
    Timer(
      const Duration(seconds: 3),
      () => Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (BuildContext context) => const SplashScreen3(),
        ),
      ),
    );
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

           Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              

              const Spacer(),

              const Center(
                child: GradientCircularProgressIndicator(
                  progress: 0.35,
                  size: 60,
                  strokeWidth: 8,
                  backgroundColor: AppColors.primaryGradientStart,
                  gradient: SweepGradient(
                    colors: [
                      AppColors.primaryGradientStart,
                      AppColors.primaryGradientEnd,
                    ],
                    startAngle: -pi / 2,
                    endAngle: pi,
                  ),
                ),
              ),
                const SizedBox(height: 40), 


              Text(
                'Redefining Defence',
                style: GoogleFonts.almarai(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                )
                
               
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
                )
                
                
                
              ),
            ],
          ),
        ),

          Positioned(
            // top: screenHeight * 0.5,
            left: 20,
            child: SafeArea(child: Image.asset("images/nigeria_img.png"))
            ),
        ],
      ),
    );
  }
}