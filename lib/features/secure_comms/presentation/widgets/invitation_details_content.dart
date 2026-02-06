import 'package:defcomm/core/theme/app_colors.dart';
import 'package:defcomm/features/secure_comms/data/models/inviter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:google_fonts/google_fonts.dart';

// This is the content that will appear below the expanded card
class InvitationDetailsContent extends StatelessWidget {
  final Inviter inviter;
  final VoidCallback onConfirm;
  const InvitationDetailsContent({super.key, required this.inviter, required this.onConfirm});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
      color: AppColors.primaryWhite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIcon(),
          _buildTitleAndSubtitle(),
          const SizedBox(height: 24),
          _buildInviterDetails(),
          const SizedBox(height: 32),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    return SizedBox(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset("images/featured_icon.png"),
          Column(
            children: [
              IconButton(onPressed: () {}, icon: Icon(Icons.close, color: AppColors.greyText4,)),
              Text("")
            ],
          )
        ],
      )
    ); 
  }

  Widget _buildTitleAndSubtitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [
        const SizedBox(width: 8),
        Text(
          'Defcomm Secure Invitation',
          style: GoogleFonts.inter(
            color: AppColors.greyText,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'You are invited to join Defcomm. Use the button to confirm your acceptance.',
          style: GoogleFonts.inter(color: AppColors.greyText2, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildInviterDetails() {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundImage: AssetImage(inviter.imageUrl),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              inviter.name,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: AppColors.greyText3,
                fontSize: 14
              ),
            ),
            Text(
              inviter.email,
              style: GoogleFonts.inter(color: Colors.grey.shade400,  fontWeight: FontWeight.w400, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            
            onPressed: () {
              /*  },
style: ElevatedButton.styleFrom(
backgroundColor: const Color(0xFF4B5320), // Dark Olive Green
padding: const EdgeInsets.symmetric(vertical: 16),
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
),
child: Text('Confirm', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
),
),
const SizedBox(height: 12),
SizedBox(
width: double.infinity,
child: OutlinedButton(
onPressed: () {  */
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.tertiaryGreen,
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: Colors.grey.shade600),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Confirm',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ),
        ),

        SizedBox(height: 10,),


        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onConfirm,
            // () {
              /* },
style: ElevatedButton.styleFrom(
backgroundColor: const Color(0xFF4B5320), // Dark Olive Green
padding: const EdgeInsets.symmetric(vertical: 16),
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
),
child: Text('Confirm', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
),
),
const SizedBox(height: 12),
SizedBox(
width: double.infinity,
child: OutlinedButton(
onPressed: () {  */
            // },
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.primaryWhite,
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: AppColors.greyText5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: AppColors.greyText,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
