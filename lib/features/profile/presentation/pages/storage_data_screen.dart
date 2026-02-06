import 'package:defcomm/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get_storage/get_storage.dart';


class StorageDataScreen extends StatefulWidget {
  const StorageDataScreen({super.key});

  @override
  State<StorageDataScreen> createState() => _StorageDataScreenState();
}

class _StorageDataScreenState extends State<StorageDataScreen> {
  final box = GetStorage();
  late String _name;
  late String _initials;
  
  bool _useLessData = false;
  bool _autoDownloadWifi = true;

  @override
  void initState() {
    super.initState();
    _name = box.read("name") ?? "User";
    _initials = _getInitials(_name);
  }

  String _getInitials(String name) {
    if (name.isEmpty) return "";
    List<String> nameParts = name.trim().split(" ");
    if (nameParts.length > 1) {
      return "${nameParts[0][0]}${nameParts[1][0]}".toUpperCase();
    }
    return nameParts[0].isNotEmpty ? nameParts[0][0].toUpperCase() : "";
  }

  @override
  Widget build(BuildContext context) {
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
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Storage and Data',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                  
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.white.withOpacity(0.9),
                          child: Text(
                            _initials,
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
                              _name,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.greenAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Online',
                                  style: GoogleFonts.poppins(
                                    color: Colors.greenAccent,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    
                    Divider(
                      color: Colors.white.withOpacity(0.1),
                      thickness: 1,
                    ),
                    const SizedBox(height: 20),

                    
                    _buildReusableRow(
                      icon: Icons.folder_open_outlined,
                      text: "Manage Storage",
                      trailingIcon: Icons.arrow_forward_ios,
                      onTap: () {
                         // Navigate to detail
                      },
                    ),

                    _buildReusableRow(
                      icon: Icons.data_usage,
                      text: "Network Usage",
                      trailingText: "2.1 GB", 
                      trailingIcon: Icons.arrow_forward_ios,
                      onTap: () {},
                    ),

                    const SizedBox(height: 10),
                    Divider(color: Colors.white.withOpacity(0.05)),
                    const SizedBox(height: 10),

                    _buildReusableRow(
                      icon: Icons.phone_in_talk_outlined,
                      text: "Use less data for calls",
                      isSwitch: true,
                      switchValue: _useLessData,
                      onChanged: (val) {
                        setState(() => _useLessData = val);
                      },
                    ),

                    _buildReusableRow(
                      icon: Icons.wifi,
                      text: "Media Auto-Download (Wi-Fi)",
                      isSwitch: true,
                      switchValue: _autoDownloadWifi,
                      onChanged: (val) {
                        setState(() => _autoDownloadWifi = val);
                      },
                    ),
                    
                    _buildReusableRow(
                      icon: Icons.delete_outline,
                      text: "Clear Cache",
                      textColor: Colors.redAccent,
                      iconColor: Colors.redAccent,
                      onTap: () {
                         // Clear cache logic
                      },
                    ),
                  ],
                ),
              ),
            ),
          
        ),
        ])
    
      
    );
    
  }


  Widget _buildReusableRow({
    required IconData icon,
    required String text,
    Color? iconColor,
    Color? textColor,
    
    String? trailingText,
    
    IconData? trailingIcon,
    
    bool isSwitch = false,
    bool switchValue = false,
    Function(bool)? onChanged,
    
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: isSwitch ? () => onChanged?.call(!switchValue) : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor ?? Colors.white70,
              size: 24,
            ),
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
                style: GoogleFonts.poppins(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
            ],

            if (isSwitch)
              Switch(
                value: switchValue,
                onChanged: onChanged,
                activeColor: Colors.green,
                activeTrackColor: Colors.green.withOpacity(0.3),
                inactiveThumbColor: Colors.grey,
                inactiveTrackColor: Colors.grey.withOpacity(0.3),
              )
            else if (trailingIcon != null)
              Icon(
                trailingIcon,
                color: Colors.white24,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}