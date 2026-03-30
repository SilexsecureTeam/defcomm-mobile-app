import 'package:defcomm/core/di/service_initilaizer.dart';
import 'package:defcomm/core/theme/app_colors.dart';
import 'package:defcomm/features/group_chat/presentation/bloc/group_chat_bloc.dart';
import 'package:defcomm/features/group_chat/presentation/bloc/group_chat_event.dart';
import 'package:defcomm/features/group_chat/presentation/pages/group_chat_screen.dart';
import 'package:defcomm/features/groups/data/models/group_status.dart';
import 'package:defcomm/features/groups/domain/entities/group_entity.dart';
import 'package:defcomm/features/groups/presentation/bloc/group_bloc.dart';
import 'package:defcomm/features/groups/presentation/bloc/group_event.dart';
import 'package:defcomm/features/groups/presentation/bloc/group_mebers_event.dart';
import 'package:defcomm/features/groups/presentation/bloc/group_member_bloc.dart';
import 'package:defcomm/features/groups/presentation/bloc/group_state.dart';
import 'package:defcomm/features/groups/presentation/widgets/animated_group_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<GroupBloc>().add(FetchAllGroups());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  padding: const EdgeInsets.fromLTRB(16, 36, 16, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).maybePop(),
                        child: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'SECURE GROUPS',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.transparent, width: 2.5),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    dividerColor: Colors.transparent,
                    indicatorColor: AppColors.primaryGradientStart,
                    tabs: [
                      Text(
                        'MY GROUPS',
                        style: GoogleFonts.poppins(
                          color: AppColors.primaryWhite,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      Text(
                        'PENDING',
                        style: GoogleFonts.poppins(
                          color: AppColors.primaryWhite,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: BlocConsumer<GroupBloc, GroupState>(
                    listener: (context, state) {
                      if (state is GroupActionSuccess) {
                        debugPrint("${state.message}");
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text(state.message),
                              backgroundColor: AppColors.tertiaryGreen,
                            ),
                          );
                      } else if (state is GroupFailure) {
                        debugPrint("${state.message}");
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text(state.message),
                              backgroundColor: AppColors.tertiaryGreen,
                            ),
                          );
                      }
                    },
                    builder: (context, state) {
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _buildStateContent(state),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateContent(GroupState state) {
    if (state is GroupLoading && state is! GroupLoaded) {
      return const Center(
        key: Key('loading'),
        child: CircularProgressIndicator(),
      );
    }
    if (state is GroupLoaded) {
      return TabBarView(
        key: const Key('loaded'),
        controller: _tabController,
        children: [
          _buildGroupList(state.joinedGroups, isPending: false),
          _buildGroupList(state.pendingGroups, isPending: true),
        ],
      );
    }
    if (state is GroupFailure) {
      return Center(
        key: Key('failure'),
        child: Text(state.message, style: TextStyle(color: Colors.white)),
      );
    }
    return const Center(
      key: Key('initial'),
      child: Text("Welcome to Groups!", style: TextStyle(color: Colors.white)),
    );
  }

  Widget _buildGroupList(List<GroupEntity> groups, {required bool isPending}) {
    if (groups.isEmpty) {
      return Center(
        child: Text("No ${isPending ? 'pending' : 'joined'} groups found."),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return InkWell(
          onTap: isPending
              ? () {
                Fluttertoast.showToast(msg: "Not yet a member ");
              } 
              : () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MultiBlocProvider(
                        providers: [
                          // If GroupChatBloc is a singleton in get_it:
                          BlocProvider<GroupChatBloc>.value(
                            value: serviceLocator<GroupChatBloc>(),
                          ),

                          BlocProvider(
                            create: (_) =>
                                serviceLocator<GroupMembersBloc>()
                                  ..add(FetchGroupMembers(group.groupId)),
                          ),
                        ],
                        child: GroupChatScreen(
                          groupIdEn: group
                              .groupId, 
                          groupName: group.groupName,
                          group: group,
                        ),
                      ),
                    ),
                  );
                },
          child: AnimatedGroupListItem(
            key: ValueKey(group.id),
            group: group,
            isPending: isPending,
            index: index,
            
          ),
        );
      },
    );
  }
}
