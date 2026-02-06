import 'package:defcomm/core/theme/app_colors.dart';
import 'package:flutter/material.dart';



class CustomTextField extends StatelessWidget {
  final String hintText;
  final bool isPassword;
  final IconData prefixIcon;

  const CustomTextField({
    super.key,
    required this.hintText,
    this.isPassword = false,
    required this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white), 
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        prefixIcon: Icon(prefixIcon, color: AppColors.secondaryGreen),
        fillColor: Colors.black.withOpacity(0.3),
        filled: true,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.3),
            width: 1.0,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(
            color: AppColors.secondaryGreen,
            width: 2.0,
          ),
        ),
      ),
    );
  }
}