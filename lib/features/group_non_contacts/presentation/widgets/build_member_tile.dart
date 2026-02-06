import 'package:defcomm/core/theme/app_colors.dart';
import 'package:defcomm/features/contact/presentation/widgets/add_contact_dialog.dart';
import 'package:defcomm/features/group_non_contacts/domain/entities/unknown_group_member.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BuildMemberTile extends StatelessWidget {
  const BuildMemberTile({
    super.key,
    required this.context,
    required this.m,
  });

  final BuildContext context;
  final UnknownGroupMember m;

  @override
  Widget build(BuildContext context) {
    // Logic for display name
    // final displayName = (m?.trim().isNotEmpty ?? false)
    //     ? m.memberName!
    //     : 'Unknown user (#${m.memberId ?? '—'})';

    final displayName = (m.name?.trim().isNotEmpty ?? false) ? m.name! : 'Unknown user (#${m.memberId ?? '—'})';



    return Container(
      margin: const EdgeInsets.only(bottom: 12), // Spacing between items
      decoration: BoxDecoration(
        color: AppColors.tertiaryGreen, // White Card style
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Trigger your Add Contact Logic
            showAddContactDialog(
              context: context,
              memberId: m.id ?? "",
              displayName: displayName,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Avatar
                Container(
                  height: 45,
                  width: 45,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.settingAccountGreen.withOpacity(0.5),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      (m.name != null && m.name!.isNotEmpty)
                          ? m.name![0].toUpperCase()
                          : '?',
                      style: GoogleFonts.poppins(
                        color: AppColors.secondaryGreen, // Dark text on light avatar
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                

                // Text Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: GoogleFonts.poppins(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        // Keeping your masked ID logic
                        '*************', 
                        style: GoogleFonts.poppins(
                          color: AppColors.quickAction1 ?? Colors.grey,
                          fontSize: 10,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Trailing Action Icon (Indicates interactivity)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1,
                    color: Colors.black45,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
