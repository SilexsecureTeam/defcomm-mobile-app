
// Splash Screen Widget
import 'dart:async';

import 'package:defcomm/core/theme/app_colors.dart';
import 'package:defcomm/features/splash/presentation/pages/splash_screen_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SplashScreen1 extends StatefulWidget {
  const SplashScreen1({Key? key}) : super(key: key);

  @override
  State<SplashScreen1> createState() => _SplashScreen1State();
}

class _SplashScreen1State extends State<SplashScreen1> {
  @override
  void initState() {
    super.initState();
    Timer(
      const Duration(seconds: 3),
      () => Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (BuildContext context) => const SplashScreen2(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

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
            // top: screenHeight * 0.5,
            left: screenWidth * 0.05,
            child: SafeArea(child: Image.asset("images/nigeria_img.png"))
            ),
        ],
      ),
    );
  }
}


