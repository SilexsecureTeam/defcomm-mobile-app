import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../features/settings/presentation/bloc/settings_bloc.dart';
import '../../../../features/settings/presentation/bloc/settings_event.dart';
import '../../../../features/settings/presentation/bloc/settings_state.dart';
import '../../../../features/settings/domain/entities/shield_settings.dart';

class ReadingOptionsDialog extends StatelessWidget {
  const ReadingOptionsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    // Colors based on your dark theme image
    const backgroundColor = Color(0xFF1F2628); // Dark grey/black
    const activeColor = Color(0xFF53E233); // Bright Green
    const inactiveThumbColor = Colors.white; 
    const inactiveTrackColor = Colors.grey;

    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        final currentMethod = state.shieldRevealMethod;

        return Dialog(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Reading Options",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Option 1: Tap
                _buildSwitchRow(
                  context,
                  label: "Tap to read",
                  isActive: currentMethod == ShieldRevealMethod.tap,
                  onChanged: (val) {
                    if (val) _updateMethod(context, ShieldRevealMethod.tap);
                  },
                  activeColor: activeColor,
                ),

                const SizedBox(height: 10),

                // Option 2: Long Press
                _buildSwitchRow(
                  context,
                  label: "Long press to read",
                  isActive: currentMethod == ShieldRevealMethod.longPress,
                  onChanged: (val) {
                     if (val) _updateMethod(context, ShieldRevealMethod.longPress);
                  },
                  activeColor: activeColor,
                ),

                const SizedBox(height: 10),

                // Option 3: Swipe
                _buildSwitchRow(
                  context,
                  label: "Swipe to read",
                  isActive: currentMethod == ShieldRevealMethod.swipe,
                  onChanged: (val) {
                     if (val) _updateMethod(context, ShieldRevealMethod.swipe);
                  },
                  activeColor: activeColor,
                ),

                const SizedBox(height: 25),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF388E3C), // Darker green button
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Close",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _updateMethod(BuildContext context, ShieldRevealMethod method) {
    context.read<SettingsBloc>().add(ChangeShieldRevealMethod(method));
  }

  Widget _buildSwitchRow(
    BuildContext context, {
    required String label,
    required bool isActive,
    required Function(bool) onChanged,
    required Color activeColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        Switch(
          value: isActive,
          onChanged: onChanged,
          activeColor: activeColor,
          activeTrackColor: activeColor.withOpacity(0.4),
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: Colors.grey.withOpacity(0.5),
        ),
      ],
    );
  }
}