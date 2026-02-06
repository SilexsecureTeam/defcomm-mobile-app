import 'package:defcomm/core/theme/app_colors.dart';
import 'package:defcomm/features/home/presentation/widgets/annoucement_carousel.dart';
import 'package:defcomm/features/home/presentation/widgets/bottom_action_bar.dart';
import 'package:defcomm/features/home/presentation/widgets/header_widget.dart';
import 'package:defcomm/features/home/presentation/widgets/quick_action.dart';
import 'package:defcomm/features/home/presentation/widgets/secure_comms_widget.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;


    return Scaffold(
      backgroundColor: const Color(0xFF1B200A),
      body: Stack(
        children: [
          Container(
            decoration:  BoxDecoration(
              gradient: AppColors.dashboardBackgroundColor
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 10, left: 18, right: 18, bottom: 5),
                    child: HeaderWidget(),
                  ),
                Padding(
                  padding: EdgeInsets.only(top: 10, left: 18, right: 18, bottom: 10),
                  child: SecureCommsWidget(showAllButton: true, showNameText: true, showBar: true,),
                ),

                Padding(
                  padding: EdgeInsets.only( left: 18, right: 18, bottom: 30),
                  child: QuickActionsWidget(),
                ),

                Padding(
                  padding: EdgeInsets.only( left: 18, right: 18, bottom: 30),
                  child: AnnouncementCarousel(),
                ),

                Padding(
                  padding: EdgeInsets.only( left: 18, right: 18, bottom: 30),
                  child: BottomActionBar(),
                ),


                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}