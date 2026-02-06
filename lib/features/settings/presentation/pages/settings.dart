import 'package:defcomm/core/theme/app_colors.dart';
import 'package:defcomm/features/linked_devices/presenation/pages/linked_devices_screen.dart';
import 'package:defcomm/features/settings/presentation/widgets/shield_setting_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings>  with WidgetsBindingObserver {
   @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      
      // context.read<SettingsBloc>().add(CheckNotificationStatus());
    }
  }

  @override
  Widget build(BuildContext context) {
   

    return SettingsView();
  }
}

class SettingsView extends StatelessWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // App Colors extracted from image
    const Color cardColor = Color(0xFF243033); 
    const Color primaryGreen = Color(0xFF2E7D32); 
    const Color textWhite = Colors.white;
    const Color textGrey = Colors.white54;

    final box = GetStorage();
    String name = box.read("name") ?? "You";

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
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Settings",
                        style: GoogleFonts.poppins(
                          color: Color(
                            0xFF4CA6A8,
                          ),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Icon(
                            Icons.security,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            name,
                            style: GoogleFonts.poppins(
                              color: textWhite,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(color: Colors.white10),

                Expanded(
                  child: BlocBuilder<SettingsBloc, SettingsState>(
                    builder: (context, state) {
                      return ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          const SizedBox(height: 10),
                          Text(
                            "ACCOUNT SETTINGS",
                            style: GoogleFonts.poppins(
                              color: Color(0xFF4CA6A8),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),

                          _SettingsTile(
                            title: "Edit profile",
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: textGrey,
                            ),
                            onTap: () {},
                          ),

                          _SettingsTile(
                            title: "Change password",
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: textGrey,
                            ),
                            onTap: () {},
                          ),

                          _SettingsTile(
                            title: "Shield Message Setting",
                            trailing: Text(
                              state.shieldRevealMethod.shortName,
                              style: TextStyle(color: textGrey, fontSize: 13),
                            ),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) {
                                  
                                  return BlocProvider.value(
                                    value: context.read<SettingsBloc>(),
                                    child: ShieldSettingDialog(
                                      currentMethod: state.shieldRevealMethod,
                                    ),
                                  );
                                },
                              );
                            },
                          ),

                          _SettingsTile(
                            title: "Hide Messages",
                            trailing: Switch(
                              value: state.hideMessages,
                              activeColor: primaryGreen,
                              onChanged: (val) {
                                context.read<SettingsBloc>().add(
                                  ToggleHideMessages(val),
                                );
                              },
                            ),
                          ),

                          _SettingsTile(
                            title: "App Language",
                            trailing: Text(
                              "English (US)",
                              style: GoogleFonts.poppins(
                                color: textGrey,
                                fontSize: 13,
                              ),
                            ),
                            onTap: () {},
                          ),

                          _SettingsTile(
                            title: "Chat Language",
                            trailing: Text(
                              "English (US)",
                              style: GoogleFonts.poppins(
                                color: textGrey,
                                fontSize: 13,
                              ),
                            ),
                            onTap: () {},
                          ),

                          // Walkie Language
                          _SettingsTile(
                            title: "Walkie Language",
                            trailing: Text(
                              "English (US)",
                              style: GoogleFonts.poppins(
                                color: textGrey,
                                fontSize: 13,
                              ),
                            ),
                            onTap: () {},
                          ),

                          _SettingsTile(
                            title: "Push Notifications",
                            trailing: Switch(
                              value: state.pushNotifications,
                              activeColor: primaryGreen,
                              onChanged: (val) {
                                context.read<SettingsBloc>().add(
                                  TogglePushNotifications(val),
                                );
                              },
                            ),
                          ),

                          // General Setting
                          _SettingsTile(
                            title: "General Setting",
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: textGrey,
                            ),
                            onTap: () {},
                          ),

                          _SettingsTile(
                            title: "Linked Devices",
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: textGrey,
                            ),
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => LinkedDevicesPage()));
                            },
                          ),
                        ],
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
}

// --- Helper Widgets ---

class _SettingsTile extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({required this.title, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final bool isSelected;

  const _NavBarItem({required this.icon, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      color: isSelected
          ? const Color(0xFF1B5E20)
          : Colors.transparent, // Dark Green highlight
      child: Icon(
        icon,
        color: isSelected ? Colors.white : Colors.grey,
        size: 26,
      ),
    );
  }
}
