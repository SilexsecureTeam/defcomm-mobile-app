// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();
  // 36460A

  static const Color primaryGradientStart = Color(0xFF65850C);
  static const Color primaryGradientEnd = Color(0xff000000);
  static const Color backgroundGreen = Color(0xFF2C390A);
  static const Color primaryWhite = Color(0xffFFFFFF);
  static const Color walkieRed = Color(0xffAD0606);
  static const Color secondaryGreen = Color(0xff47AA49);
  static const Color secondaryWhite = Color(0xffADADAD);
  static const Color tertiaryGreen = Color(0xff36460A);
  static const Color phoneInputGreen = Color(0xff3E4A1F);
  static const Color phoneInputGreenBorder = Color(0xffE3E5E5);
  static const Color otpFieldUnFocusBorder = Color(0xffD9D9D9);
  static const Color settingAccountGreen = Color(0xff89AF20);
  static const Color vectorsBacgroundContainerColor = Color(0xff121212);
  static const Color secureCommsVerticalBar = Color(0xff759719);
  static const Color quickAction1 = Color(0xffC6FC2B);
  static const Color quickAction2 = Color(0xffFEFEFE);
  static const Color carouselColor = Color(0xFFD9E9A8);
  static const Color carouselTextColor = Color(0xFF484A4B);
   static const Color notificationCard = Color(0xFF242C32);
   static const Color greyText = Color(0xFF181D27);
   static const Color greyText2 = Color(0xFF535862);

static const Color greyText3 = Color(0xFF414651);
static const Color greyText4 = Color(0xFF535862);
static const Color greyText5 = Color(0xFFD5D7DA);
  static const Color switchValueColor = Color(0xffCCCDCD);
  // static const Color activeSwitchValueColor = Color(0xff89AF20);







  // Gradient colors
  static LinearGradient get appGradientColor => const LinearGradient(
        colors: [primaryGradientStart, primaryGradientEnd]
      );

      static LinearGradient get angularGradint => const LinearGradient(
        colors: [Color.fromRGBO(211, 255, 86, 1), Color.fromRGBO(0, 175, 170, 0)]
      );

      static LinearGradient get appGradientOverlay => LinearGradient(
        colors: [
          tertiaryGreen.withOpacity(0.5),
          primaryGradientEnd.withOpacity(0.5),   
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

      static LinearGradient get appGradientColor2 => LinearGradient(
                colors: [
                  // Color(0xFF3D4F1B),
                  tertiaryGreen,
                  Color(0xFF000000),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.9],
              );
    
    static LinearGradient get dashboardBackgroundColor => LinearGradient(
      colors: [
                  Color(0xFF000000),
                  tertiaryGreen
                  // Color(0xFF3D4F1B),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.9],
    );


}