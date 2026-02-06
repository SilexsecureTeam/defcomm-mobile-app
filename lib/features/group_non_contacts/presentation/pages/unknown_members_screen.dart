import 'package:defcomm/core/theme/app_colors.dart';
import 'package:defcomm/features/contact/presentation/widgets/add_contact_dialog.dart';
import 'package:defcomm/features/group_non_contacts/presentation/blocs/unknown_members_bloc.dart';
import 'package:defcomm/features/group_non_contacts/presentation/blocs/unknown_members_event.dart';
import 'package:defcomm/features/group_non_contacts/presentation/blocs/unknown_members_state.dart';
import 'package:defcomm/features/group_non_contacts/presentation/widgets/build_member_tile.dart';
import 'package:defcomm/features/group_non_contacts/presentation/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../init_dependencies.dart';
import '../../domain/entities/unknown_group_member.dart';

class UnknownMembersScreen extends StatelessWidget {
  final String groupId;
  final String? groupName;

  const UnknownMembersScreen({
    super.key,
    required this.groupId,
    this.groupName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Inject the Bloc and immediately trigger the fetch event
      create: (context) =>
          serviceLocator<UnknownMembersBloc>()
            ..add(FetchUnknownMembers(groupId)),
      child: Scaffold(
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
                      vertical: 12.0,
                    ),
                    child: CustomAppBar(context: context, groupName: groupName),
                  ),

                  Expanded(
                    child: BlocBuilder<UnknownMembersBloc, UnknownMembersState>(
                      builder: (context, state) {
                        if (state is UnknownMembersLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (state is UnknownMembersError) {
                          return Center(child: Text('Error: ${state.message}'));
                        }

                        if (state is UnknownMembersLoaded) {
                          if (state.members.isEmpty) {
                            return const Center(
                              child: Text(
                                "All members are already in your contacts.",
                              ),
                            );
                          }

                          return ListView.separated(
                            itemCount: state.members.length,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 12.0,
                            ),
                            separatorBuilder: (ctx, i) => const Divider(
                              height: 1,
                              color: Colors.transparent,
                            ),
                            itemBuilder: (context, index) {
                              final member = state.members[index];
                              return BuildMemberTile(
                                context: context,
                                m: member,
                              );
                            },
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
}

