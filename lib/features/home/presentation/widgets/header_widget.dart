import 'package:defcomm/core/theme/app_colors.dart';
import 'package:defcomm/core/widgets/real-time.dart';
import 'package:defcomm/features/groups/presentation/pages/groups_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color kDarkGreen = Color(0xFF2C390A);
const Color kLightGreen = Color(0xFFA1C13B);

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return SizedBox(
      height: h * 0.25, // one shared height for BOTH sides
      child: Row(
        children: [
         
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: kDarkGreen),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        "images/seciure_mode_active.png",
                        height: 10,
                        width: 10,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'SECURE MODE ACTIVE',
                        style: GoogleFonts.inter(
                          color: AppColors.settingAccountGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Expanded(
                    child: RealTimeClock(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            flex: 3,
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: kDarkGreen),
                    child: GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                      children: const [
                        DashBoardVectorContainer(url: "images/network.png"),
                        DashBoardVectorContainer(url: "images/bluetooth.png"),
                        DashBoardVectorContainer(url: "images/settings.png"),
                        DashBoardVectorContainer(url: "images/camera.png"),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Expanded(
                  flex: 1,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GroupsScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.group,
                              size: 20, color: AppColors.tertiaryGreen),
                          const SizedBox(width: 4),
                          Text(
                            'SecureGroup',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class DashBoardVectorContainer extends StatelessWidget {
  const DashBoardVectorContainer({super.key, required this.url, this.onTap});
  final String url;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          // shape: BoxShape.circle,
          borderRadius: BorderRadius.circular(screenWidth * 0.05),
          color: AppColors.vectorsBacgroundContainerColor,
        ),
        child: Center(
          child: Image.asset(
            url,
            height: screenHeight * 0.035,
            width: screenWidth * 0.064,
          ),
        ),
      ),
    );
  }
}
