import 'package:defcomm/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class QuickActionsWidget extends StatelessWidget {
  const QuickActionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: _actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final action = _actions[index];
          return _QuickActionItem(
            iconPath: action.iconPath,
            color: action.color,
            onTap: action.onTap,
          );
        },
      ),
    );
  }
}

class _QuickActionData {
  final String iconPath;
  final Color color;
  final VoidCallback? onTap;

  const _QuickActionData({
    required this.iconPath,
    required this.color,
    this.onTap,
  });
}

const List<_QuickActionData> _actions = [
  _QuickActionData(
    iconPath: "images/phone.png",
    color: AppColors.quickAction1,
  ),
  _QuickActionData(
    iconPath: "images/walkie_dash.png",
    color: AppColors.quickAction2,
  ),
  _QuickActionData(
    iconPath: "images/file_share.png",
    color: AppColors.quickAction2,
  ),
  _QuickActionData(
    iconPath: "images/store.png",
    color: AppColors.quickAction2,
  ),
  _QuickActionData(
    iconPath: "images/action_wifi.png",
    color: AppColors.quickAction2,
  ),
  _QuickActionData(
    iconPath: "images/action_E.png",
    color: AppColors.quickAction2,
  ),

   _QuickActionData(
    iconPath: "images/bluethoooot.png",
    color: AppColors.quickAction2,
  ),

   _QuickActionData(
    iconPath: "images/action_camera.png",
    color: AppColors.quickAction2,
  ),

   _QuickActionData(
    iconPath: "images/action_camera.png",
    color: AppColors.quickAction2,
  ),
];

class _QuickActionItem extends StatelessWidget {
  final String iconPath;
  final Color color;
  final VoidCallback? onTap;

  const _QuickActionItem({
    required this.iconPath,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Image.asset(
            iconPath,
            height: 40,
            width: 40,
          ),
        ),
      ),
    );
  }
}
