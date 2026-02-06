

import 'dart:async';

import 'package:defcomm/core/theme/app_colors.dart';
import 'package:defcomm/features/onboarding/presentation/pages/onboarding_screen.dart';
import 'package:flutter/material.dart';

class SplashScreen3 extends StatefulWidget {
  const SplashScreen3({super.key});

  @override
  State<SplashScreen3> createState() => _SplashScreen3State();
}

class _SplashScreen3State extends State<SplashScreen3> {

  @override
  void initState() {
    super.initState();
    Timer(
      const Duration(seconds: 3),
      () => Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (BuildContext context) => const OnboardingScreen(),
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

              Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(
                    color: AppColors.walkieRed,
                    borderRadius: BorderRadius.circular(30)
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadiusGeometry.circular(30),
                    child: Image.asset("images/walkie.png", height: 90, width: 40,),
                  
                  ),
                ),
              ),

                const SizedBox(height: 40), 

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