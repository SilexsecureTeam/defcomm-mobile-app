// lib/features/group/presentation/pages/group_members_screen.dart
import 'package:defcomm/core/theme/app_colors.dart';
import 'package:defcomm/features/contact/presentation/widgets/add_contact_dialog.dart';
import 'package:defcomm/features/groups/presentation/bloc/group_embers_state.dart';
import 'package:defcomm/features/groups/presentation/bloc/group_mebers_event.dart';
import 'package:defcomm/features/groups/presentation/bloc/group_member_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/group_member_model.dart';




class GroupMembersScreen extends StatelessWidget {
  final String groupId;
  final String? groupName;

  const GroupMembersScreen({
    required this.groupId,
    this.groupName,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
  
    return BlocProvider.value(
      value: context.read<GroupMembersBloc>()..add(FetchGroupMembers(groupId)),
      child: Scaffold(
        backgroundColor: AppColors.tertiaryGreen,
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.dashboardBackgroundColor,
              ),
            ),

            // 2. Main Content
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: _buildCustomAppBar(context),
                  ),

                  const SizedBox(height: 10),

                  Expanded(
                    child: BlocBuilder<GroupMembersBloc, GroupMembersState>(
                      builder: (context, state) {
                        if (state is GroupMembersLoading ||
                            state is GroupMembersInitial) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          );
                        }

                        if (state is GroupMembersFailure) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.redAccent, size: 40),
                                const SizedBox(height: 8),
                                Text(
                                  state.message,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          );
                        }

                        if (state is GroupMembersLoaded) {
                          final members = state.members;

                          if (members.isEmpty) {
                            return Center(
                              child: Text(
                                'No members found.',
                                style: GoogleFonts.poppins(
                                  color: Colors.white60,
                                ),
                              ),
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 20,
                                  bottom: 12,
                                ),
                                child: Text(
                                  "${members.length} MEMBERS",
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white38,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              
                              // The List
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  itemCount: members.length,
                                  itemBuilder: (context, index) {
                                    final m = members[index];
                                    return _buildMemberTile(context, m);
                                  },
                                ),
                              ),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildCustomAppBar(BuildContext context) {
    return Row(
      children: [
        // Back Button
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        
        // Group Name & Label
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                groupName ?? 'Group Members',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Group Details',
                style: GoogleFonts.poppins(
                  color: Colors.white60,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMemberTile(BuildContext context, dynamic m) {
    final displayName = (m.memberName?.trim().isNotEmpty ?? false)
        ? m.memberName!
        : 'Unknown user (#${m.memberId ?? '—'})';

    return Container(
      margin: const EdgeInsets.only(bottom: 12), 
      decoration: BoxDecoration(
        color: Colors.white,
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
              memberId: m.memberIdEncrypt ?? "",
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
                    color: AppColors.settingAccountGreen.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.settingAccountGreen.withOpacity(0.5),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      (m.memberName != null && m.memberName!.isNotEmpty)
                          ? m.memberIdEncryp
                          : '?',
                      style: GoogleFonts.poppins(
                        color: AppColors.tertiaryGreen, 
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

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
