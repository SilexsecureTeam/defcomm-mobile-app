import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/shield_settings.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';

class ShieldSettingDialog extends StatelessWidget {
  final ShieldRevealMethod currentMethod;

  const ShieldSettingDialog({
    Key? key, 
    required this.currentMethod
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1B2526), 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.white12, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Shield Message Setting",
              style: TextStyle(
                color: Color(0xFF80CBC4), 
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Choose how to reveal hidden messages",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            
            // Options
            _buildOption(context, ShieldRevealMethod.tap),
            const SizedBox(height: 12),
            _buildOption(context, ShieldRevealMethod.longPress),
            const SizedBox(height: 12),
            _buildOption(context, ShieldRevealMethod.swipe),
            
            const SizedBox(height: 25),
            
            // Close Button
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32), 
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Close",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, ShieldRevealMethod method) {
    final bool isSelected = currentMethod == method;
    final Color primaryGreen = const Color(0xFF2E7D32);

    return SizedBox(
      width: double.infinity,
      height: 45,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? primaryGreen : Colors.transparent,
          side: BorderSide(color: isSelected ? primaryGreen : Colors.white38),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: () {
          // Send event to BLoC
          context.read<SettingsBloc>().add(ChangeShieldRevealMethod(method));
          Navigator.pop(context); 
        },
        child: Text(
          method.displayName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}