import 'package:defcomm/core/theme/app_colors.dart';
import 'package:defcomm/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:defcomm/features/profile/presentation/bloc/profile_events.dart';
import 'package:defcomm/features/profile/presentation/bloc/profile_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';


enum ProfileView { menu, storage, notifications }

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final box = GetStorage();

  ProfileView _currentView = ProfileView.menu;

  bool _permissionsEnabled = true;
  bool _onlyWifiEnabled = false;

  // Storage Settings State
  bool _useLessData = false;
  bool _autoDownloadWifi = true;

  bool _mute = false;
  bool _protectedChat = false;
  bool _hideChat = false;
  bool _hideChatHistory = false;

  @override
  Widget build(BuildContext context) {

    
    // Fetch user data
    final String name = box.read("name") ?? "";
    final String initials = _getInitials(name);

    return PopScope(
      canPop: _currentView == ProfileView.menu,
      onPopInvoked: (didPop) {
        if (didPop) return;
        setState(() {
          _currentView = ProfileView.menu;
        });
      },
      child: BlocProvider(
        create: (context) => ProfileBloc()..add(MonitorInternetConnection()),
        child: Scaffold(
          backgroundColor: AppColors.tertiaryGreen,
          body: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: AppColors.dashboardBackgroundColor,
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 36),

                        // --- STATIC HEADER (Always Visible) ---
                        _buildProfileHeader(name, initials),

                        const SizedBox(height: 20),
                        Divider(color: Colors.white.withOpacity(0.1)),
                        const SizedBox(height: 20),

                        // --- DYNAMIC CONTENT ---
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                          child: _currentView == ProfileView.storage
                              ? _buildStorageView()
                              : _buildMainMenuView(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

 

  Widget _buildProfileHeader(String name, String initials) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My profiles',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 30),
        Row(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: Colors.white.withOpacity(0.9),
              child: Text(
                initials,
                style: GoogleFonts.poppins(
                  color: Colors.black87,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                BlocBuilder<ProfileBloc, ProfileState>(
                  builder: (context, state) {
                    return Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: state.isOnline
                                ? Colors.greenAccent
                                : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          state.isOnline ? 'Online' : 'Offline',
                          style: GoogleFonts.poppins(
                            color: state.isOnline
                                ? Colors.greenAccent
                                : Colors.white54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainMenuView() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Column(
      key: const ValueKey('menu'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),

        _buildMenuItem(
          url: "images/custom_notification.png",
          // icon: Icons.notifications_none_outlined,
          text: "Notification",
          onTap: () {},
          showArrow: true,
          context: context
        ),
        _buildMenuItem(
          url: "images/lock1.png",
          text: "Hide Chat History",
          onTap: () {},
          context: context
        ),
        _buildMenuItem(
          url: "images/messagetext.png",
          text: "Chats",
          onTap: () {},
          context: context
        ),
        _buildMenuItem(
          url: "images/chartcircle.png",
          text: "Storage and date",
          onTap: () {
            setState(() {
              _currentView = ProfileView.storage;
            });
          },
          context: context
        ),

        const SizedBox(height: 40),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF262F38),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Help",
                style: GoogleFonts.poppins(
                  color: AppColors.settingAccountGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              _buildSwitchItem(
                url: "images/messagequestion.png",
                text: "Permissions",
                value: _permissionsEnabled,
                onChanged: (val) => setState(() => _permissionsEnabled = val),
              ),
              const SizedBox(height: 16),
              _buildSwitchItem(
                url: "images/shieldtick.png",
                text: "Only Wi-Fi",
                value: _onlyWifiEnabled,
                onChanged: (val) => setState(() => _onlyWifiEnabled = val),
              ),
              const SizedBox(height: 16),
              
              
              const SizedBox(height: 16),

              InkWell(
                onTap: () {},
                child: Row(
                  children: [
                    Image.asset("images/messagetime.png", height: screenHeight * 0.025,
              width: screenHeight * 0.025,),
                    const SizedBox(width: 16),
                    Text(
                      "Help Center",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildStorageView() {
    return Column(
      key: const ValueKey('storage'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _currentView = ProfileView.menu),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Row(
              children: [
                const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.greenAccent,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  "Back to Settings",
                  style: GoogleFonts.poppins(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        Text(
          'Storage and Data',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),

        // Storage Options
        _buildReusableRow(
          context: context,
          url: "images/gallery.png",
          trailingText: "152",
          // icon: Icons.folder_open_outlined,
          text: "Manage Storage",
          trailingIcon: Icons.arrow_forward_ios,
          onTap: () {},
        ),
        _buildReusableRow(
          context: context,
          url: "images/mute_notification.png",
          // icon: Icons.data_usage,
          text: "Mute Notification",
          trailingText: "",
          trailingIcon: null,
          switchValue: _mute,
          isSwitch: true,
          onChanged: (val) => setState(() => _mute = val),
          onTap: () {},
        ),

        _buildReusableRow(
          context: context,
          url: "images/custom_notification.png",
          text: "Manage Storage",
          trailingIcon: Icons.arrow_forward_ios,
          onTap: () {},
        ),

        _buildReusableRow(
          context: context,
          url: "images/protected_chat.png",
          // icon: Icons.data_usage,
          text: "Protected Chat",
          trailingText: "",
          switchValue: _protectedChat,
          isSwitch: true,
          onChanged: (val) => setState(() => _mute = val),
          onTap: () {},
          trailingIcon: Icons.arrow_forward_ios,
        ),

        _buildReusableRow(
          context: context,
          url: "images/visibility.png",
          // icon: Icons.data_usage,
          text: "Hide Chat",
          trailingText: "",
          switchValue: _hideChat,
          isSwitch: true,
          onChanged: (val) => setState(() => _mute = val),
          onTap: () {},
          trailingIcon: Icons.arrow_forward_ios,
        ),

        _buildReusableRow(
          context: context,
          url: "images/visibility.png",
          // icon: Icons.data_usage,
          text: "Hide Chat History",
          trailingText: "",
          switchValue: _hideChatHistory,
          isSwitch: true,
          onChanged: (val) => setState(() => _mute = val),
          onTap: () {},
          trailingIcon: Icons.arrow_forward_ios,
        ),
        _buildReusableRow(
          context: context,
          url: "images/add_to_group.png",
          // icon: Icons.folder_open_outlined,
          text: "Add To Group",
          trailingIcon: Icons.arrow_forward_ios,
          onTap: () {},
        ),

        _buildReusableRow(
          context: context,
          url: "images/report.png",
          // icon: Icons.folder_open_outlined,
          text: "Report",
          textColor: Color(0xfffF44336),
          onTap: () {},
        ),

        _buildReusableRow(
          context: context,
          url: "images/block.png",
          // icon: Icons.folder_open_outlined,
          text: "Block",
          textColor: Color(0xfffF44336),
          onTap: () {},
        ),

        //   const SizedBox(height: 10),
        //   Divider(color: Colors.white.withOpacity(0.05)),
        //   const SizedBox(height: 10),

        //   _buildReusableRow(
        //     icon: Icons.phone_in_talk_outlined,
        //     text: "Use less data for calls",
        //     isSwitch: true,
        //     switchValue: _useLessData,
        //     onChanged: (val) => setState(() => _useLessData = val),
        //   ),
        //   _buildReusableRow(
        //     icon: Icons.wifi,
        //     text: "Media Auto-Download (Wi-Fi)",
        //     isSwitch: true,
        //     switchValue: _autoDownloadWifi,
        //     onChanged: (val) => setState(() => _autoDownloadWifi = val),
        //   ),

        //   const SizedBox(height: 20),

        //   // Example of the "Dark Card" style reused for storage info
        //  _buildReusableRow(
        //       icon: Icons.delete_outline,
        //       text: "Report",
        //       textColor: Colors.redAccent,
        //       iconColor: Colors.redAccent,
        //       onTap: () {},
        //     ),

        // const SizedBox(height: 20),

        // // Example of the "Dark Card" style reused for storage info
        // _buildReusableRow(
        //   icon: Icons.delete_outline,
        //   text: "Block",
        //   textColor: Colors.redAccent,
        //   iconColor: Colors.redAccent,
        //   onTap: () {},
        // ),
      ],
    );
  }

  // ===========Color.fromARGB(255, 51, 39, 39)================================================
  // HELPER METHODS
  // ===========================================================================

  String _getInitials(String name) {
    List<String> parts = name.trim().split(" ");
    if (parts.isEmpty) return "";
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Widget _buildMenuItem({
    required String url,
    required String text,
    required VoidCallback onTap,
    bool showArrow = false,
    required BuildContext context
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white10,
        child: Row(
          children: [
            Image.asset(url, height: screenHeight * 0.025,
              width: screenHeight * 0.025,),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            if (showArrow)
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white54,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required String url,
    required String text,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Row(
      children: [
        Image.asset(url, height: screenHeight * 0.025,
              width: screenHeight * 0.025,),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: AppColors.settingAccountGreen,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: AppColors.switchValueColor,
        ),
      ],
    );
  }

  Widget _buildReusableRow({
    required String url,
    required String text,
    Color? iconColor,
    Color? textColor,
    String? trailingText,
    IconData? trailingIcon,
    bool isSwitch = false,
    bool switchValue = false,
    Function(bool)? onChanged,
    VoidCallback? onTap,
    required BuildContext context,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return InkWell(
      onTap: isSwitch ? () => onChanged?.call(!switchValue) : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          children: [
            Image.asset(
              url,
              height: screenHeight * 0.02,
              width: screenHeight * 0.02,
            ),
            // Icon(icon, color: iconColor ?? Colors.white70, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  color: textColor ?? Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            if (trailingText != null) ...[
              Text(
                trailingText,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              ),
              SizedBox(width: screenWidth * 0.07),
            ],
            if (isSwitch)
              Switch(
                value: switchValue,
                onChanged: onChanged,
                activeColor: Colors.white,
                activeTrackColor: Colors.green,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.grey,
              ),
            if (isSwitch && trailingIcon != null)
              SizedBox(width: screenWidth * 0.07),

            if (trailingIcon != null)
              Icon(trailingIcon, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }
}
