import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';

/// Shows a one-time, brand-specific guide that deep-links the user directly
/// to their OEM battery/autostart settings screen so Defcomm can receive
/// calls and messages even when the screen is off.
///
/// Covers: Xiaomi/MIUI, Huawei/EMUI, Oppo/ColorOS, Realme, Vivo,
///         Samsung One UI, OnePlus, Asus, and generic Android.
class OemBatteryService {
  static const _channel = MethodChannel('come.deffcom.chatapp/oem_battery');
  static const _shownKey = 'oem_battery_guide_shown_v1';

  static Future<void> showGuideIfNeeded(BuildContext context) async {
    if (!Platform.isAndroid) return;

    final box = GetStorage();
    if (box.read(_shownKey) == true) return;

    final deviceInfo = DeviceInfoPlugin();
    final android = await deviceInfo.androidInfo;
    final mfr = android.manufacturer.toLowerCase();

    final _OemGuide guide = _resolveGuide(mfr);

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.battery_charging_full_rounded, color: Color(0xFF4CAF50), size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                guide.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'To receive calls and messages when your screen is off, allow Defcomm to run in the background:',
                style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 12),
              Text(
                guide.steps,
                style: const TextStyle(fontSize: 13, height: 1.7),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              box.write(_shownKey, true);
              Navigator.of(ctx).pop();
            },
            child: const Text('Later', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              box.write(_shownKey, true);
              Navigator.of(ctx).pop();
              try {
                await _channel.invokeMethod('openOemBatterySettings');
              } catch (_) {}
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Open Settings', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  static _OemGuide _resolveGuide(String mfr) {
    if (mfr.contains('xiaomi') || mfr.contains('redmi') || mfr.contains('poco')) {
      return _OemGuide(
        title: 'Xiaomi: Enable Autostart',
        steps: '1. Tap "Open Settings"\n'
            '2. Find Defcomm → Enable Autostart\n\n'
            'Also:\nSettings → Battery & Performance\n'
            '→ App Battery Saver → Defcomm\n'
            '→ Set to No Restrictions',
      );
    }
    if (mfr.contains('huawei') || mfr.contains('honor')) {
      return _OemGuide(
        title: 'Huawei: Enable App Launch',
        steps: '1. Tap "Open Settings"\n'
            '2. Find Defcomm → Enable it\n\n'
            'Also:\nSettings → Battery → App Launch\n'
            '→ Defcomm → turn ON all 3 toggles\n'
            '(Auto-launch, Secondary launch, Run in BG)',
      );
    }
    if (mfr.contains('oppo') || mfr.contains('realme')) {
      return _OemGuide(
        title: 'Oppo/Realme: Enable Autostart',
        steps: '1. Tap "Open Settings"\n'
            '2. Find Defcomm → Enable Autostart\n\n'
            'Also:\nSettings → Battery\n'
            '→ Optimisation → Defcomm\n'
            '→ Do Not Optimise',
      );
    }
    if (mfr.contains('vivo')) {
      return _OemGuide(
        title: 'Vivo: Allow Background Start',
        steps: '1. Tap "Open Settings"\n'
            '2. Find Defcomm → Allow background start\n\n'
            'Also:\niManager → App Manager → Defcomm\n'
            '→ Enable Auto-Start',
      );
    }
    if (mfr.contains('samsung')) {
      return _OemGuide(
        title: 'Samsung: Unrestricted Battery',
        steps: '1. Tap "Open Settings"\n'
            '2. Tap Battery usage\n'
            '3. Find Defcomm\n'
            '4. Set to Unrestricted',
      );
    }
    if (mfr.contains('oneplus')) {
      return _OemGuide(
        title: 'OnePlus: Allow Background Activity',
        steps: '1. Tap "Open Settings"\n'
            '2. Find Defcomm → Enable it\n\n'
            'Also:\nSettings → Battery\n'
            '→ Battery Optimisation → Defcomm\n'
            '→ Don\'t Optimise',
      );
    }
    if (mfr.contains('asus')) {
      return _OemGuide(
        title: 'Asus: Enable Autostart',
        steps: '1. Tap "Open Settings"\n'
            '2. Find Defcomm → Enable Autostart\n\n'
            'Also:\nSettings → Battery\n'
            '→ Defcomm → No Restrictions',
      );
    }
    // Generic Android
    return _OemGuide(
      title: 'Allow Background Access',
      steps: '1. Tap "Open Settings"\n'
          '2. Tap Battery\n'
          '3. Find Defcomm\n'
          '4. Select Unrestricted\n'
          '   (or Don\'t Optimise)',
    );
  }
}

class _OemGuide {
  final String title;
  final String steps;
  const _OemGuide({required this.title, required this.steps});
}
