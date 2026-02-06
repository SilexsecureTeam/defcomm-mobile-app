
import 'package:defcomm/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreenBody extends StatelessWidget {
  const OnboardingScreenBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryGradientStart, AppColors.primaryGradientEnd],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.72], 
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 80), 
        
               Text(
                'DISCOVER',
                style: GoogleFonts.almarai(
                   color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,

                ) 
              ),
        
              Text(
                  'A NEW SECURE',
                  style: GoogleFonts.almarai(
                    color: AppColors.primaryGradientStart,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    // height: 1.2,
                    
                    decoration: TextDecoration.lineThrough,
                    decorationColor: AppColors.secondaryGreen,
                    decorationThickness: 1.0,
                  )                
                ),
              
              Text(
                'TECHNOLOGY',
                style: GoogleFonts.almarai(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                )
              ),
        
              const SizedBox(height: 40), 
        
               Text(
                'EXPERIENCE',
                style: GoogleFonts.almarai(color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  )               
              ),
               Text(
                'Absolute Privacy',
                style: GoogleFonts.almarai(
                  color: AppColors.primaryGradientStart,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,)
              ),
              SizedBox(height: 30,),
              Center(
                child: Text(
                  'Through Messaging',
                  style: GoogleFonts.almarai(
                    color: AppColors.secondaryGreen,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  )
                ),
              ),
               SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}