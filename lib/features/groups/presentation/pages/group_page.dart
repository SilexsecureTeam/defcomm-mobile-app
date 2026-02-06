import 'package:defcomm/core/di/service_initilaizer.dart';
import 'package:defcomm/core/theme/app_colors.dart';
import 'package:defcomm/features/group_non_contacts/presentation/pages/unknown_members_screen.dart';
import 'package:defcomm/features/groups/presentation/bloc/group_bloc.dart';
import 'package:defcomm/features/groups/presentation/bloc/group_event.dart';
import 'package:defcomm/features/groups/presentation/bloc/group_member_bloc.dart';
import 'package:defcomm/features/groups/presentation/bloc/group_state.dart';
import 'package:defcomm/features/groups/presentation/pages/group_members_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';


class GroupsPage extends StatefulWidget {
  const GroupsPage({Key? key}) : super(key: key);

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  final box = GetStorage();
  late String _userName;

  @override
  void initState() {
    super.initState();
    _userName = box.read("name") ?? "User";
    context.read<GroupBloc>().add(FetchAllGroups());
  }

  void _onCallPressed() {
    debugPrint("Call Pressed");
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.tertiaryGreen,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.dashboardBackgroundColor,
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: _buildCustomAppBar(context, _userName),
                ),

                const SizedBox(height: 10),

                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        width: double.infinity,
                        
                        constraints: BoxConstraints(
                          minHeight: size.height * 0.3,
                        ),
                        padding: const EdgeInsets.all(24.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Groups",
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Select a group to view details or manage invitations.",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Bloc Consumer
                            BlocConsumer<GroupBloc, GroupState>(
                              listener: (context, state) {
                                if (state is GroupActionSuccess) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(state.message),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                                if (state is GroupFailure) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(state.message),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              builder: (context, state) {
                                if (state is GroupLoading) {
                                  return const Padding(
                                    padding: EdgeInsets.all(20.0),
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                if (state is GroupLoaded) {
                                  final joined = state.joinedGroups;
                                  final pending = state.pendingGroups;

                                  if (joined.isEmpty && pending.isEmpty) {
                                    return Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Text(
                                        "No groups found.",
                                        style: GoogleFonts.poppins(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    );
                                  }

                                  return ListView(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    children: [
                                      if (pending.isNotEmpty) ...[
                                        _buildSectionHeader(
                                          "Pending Invitations",
                                        ),
                                        ...pending.map(
                                          (group) => _buildGroupTile(
                                            context,
                                            group,
                                            true,
                                            group.groupId,
                                            group.groupName
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                      ],

                                      if (joined.isNotEmpty) ...[
                                        _buildSectionHeader("Your Teams"),
                                        ...joined.map(
                                          (group) => _buildGroupTile(
                                            context,
                                            group,
                                            false,
                                            group.groupId,
                                            group.groupName
                                          ),
                                        ),
                                      ],
                                    ],
                                  );
                                }

                                if (state is GroupFailure) {
                                  return Text(
                                    state.message,
                                    style: TextStyle(color: Colors.red),
                                  );
                                }

                                return const SizedBox.shrink();
                              },
                            ),
                          ],
                        ),
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

  // --- HELPER WIDGETS ---

  Widget _buildCustomAppBar(BuildContext context, String? name) {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
        ),
        const CircleAvatar(
          radius: 18,
          backgroundImage: AssetImage('images/profile_img.png'),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name ?? "",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              'user',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey[400],
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildGroupTile(
    BuildContext context,
    dynamic group,
    bool isInvitation,
    String groupId,
    String? groupName
  ) {
    return GestureDetector(
      onTap: isInvitation ? () {
        // Optionally handle tap on the entire tile
      } : () {
        Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => UnknownMembersScreen(
                        groupId: groupId, 
                        groupName: groupName,
                      ),
                    ),
                  );
      }, 
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            // Icon / Avatar
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Icon(Icons.shield_outlined, color: Colors.black54),
            ),
            const SizedBox(width: 16),
      
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.groupName ?? "Unknown Group",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    "@${group.companyName?.isNotEmpty == true ? group.companyName : group.groupId}",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
      
            // Actions
            if (isInvitation)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: () {
                      context.read<GroupBloc>().add(
                        AcceptGroupInvitation(group.groupId),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () {
                      context.read<GroupBloc>().add(
                        DeclineGroupInvitation(group.groupId),
                      );
                    },
                  ),
                ],
              )
            else
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => UnknownMembersScreen(
                        groupId: groupId, 
                        groupName: groupName,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    group.status ?? "Member",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
