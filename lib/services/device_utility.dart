import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceUtility {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// 1. DETECTION: Checks if the device is a known battery-killer.
  /// Returns [true] if the manufacturer is Xiaomi, Oppo, Tecno, etc.
  static Future<bool> isChineseRom() async {
    if (!Platform.isAndroid) return false;

    try {
      final androidInfo = await _deviceInfo.androidInfo;
      final manufacturer = androidInfo.manufacturer.toLowerCase();

      // The "Hit List" of restrictive manufacturers
      const List<String> suspiciousBrands = [
        'xiaomi',
        'redmi',
        'poco',
        'oppo',
        'vivo',
        'huawei',
        'honor',
        'oneplus',
        'meizu',
        // Transsion Group (Africa/Global) - Very Aggressive
        'tecno',
        'infinix',
        'itel',
      ];

      return suspiciousBrands.contains(manufacturer);
    } catch (e) {
      debugPrint("Error detecting device manufacturer: $e");
      return false;
    }
  }

  /// 2. THE FIX: Attempts to open the specific "Auto-Start" or "Battery" page.
  /// If the specific page fails, it opens the standard App Info page as a fallback.
  static Future<void> openAutoStartSettings(BuildContext context) async {
    if (!Platform.isAndroid) return;

    final androidInfo = await _deviceInfo.androidInfo;
    final manufacturer = androidInfo.manufacturer.toLowerCase();

    // ------------------------------------------------------------------
    // THE SECRET MAP: Hidden Intent paths for various ROMs
    // Format: "package_name/activity_name"
    // ------------------------------------------------------------------
    final Map<String, List<String>> intentMap = {
      'xiaomi': [
        'com.miui.securitycenter/com.miui.permcenter.autostart.AutoStartManagementActivity',
        'com.miui.securitycenter/com.miui.powercenter.PowerSettings',
      ],
      'redmi': [
        'com.miui.securitycenter/com.miui.permcenter.autostart.AutoStartManagementActivity',
      ],
      'oppo': [
        'com.coloros.safecenter/com.coloros.safecenter.permission.startup.StartupAppListActivity',
        'com.oppo.safe/com.oppo.safe.permission.startup.StartupAppListActivity',
      ],
      'vivo': [
        'com.vivo.permissionmanager/com.vivo.permissionmanager.activity.BgStartUpManagerActivity',
      ],
      'huawei': [
        'com.huawei.systemmanager/com.huawei.systemmanager.optimize.process.ProtectActivity',
      ],
      'oneplus': [
        'com.oneplus.security/com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity',
      ],
      // Transsion Group (Tecno/Infinix) - Uses "Phone Master"
      'tecno': [
        'com.transsion.phonemaster/com.transsion.phonemaster.AutoStartManagementActivity',
        'com.transsion.phonemaster/com.transsion.phonemaster.entry.AutoStartManagementActivity',
      ],
      'infinix': [
        'com.transsion.phonemaster/com.transsion.phonemaster.AutoStartManagementActivity',
      ],
      'itel': [
        'com.transsion.phonemaster/com.transsion.phonemaster.AutoStartManagementActivity',
      ],
    };

    bool openedSpecificSettings = false;

    // A. Try Manufacturer Specific Intents
    if (intentMap.containsKey(manufacturer)) {
      for (final path in intentMap[manufacturer]!) {
        final split = path.split('/');
        final packageName = split[0];
        final componentName = split[1];

        try {
          final intent = AndroidIntent(
            action: 'android.intent.action.MAIN',
            package: packageName,
            componentName: componentName,
            // FLAG_ACTIVITY_NEW_TASK is crucial for launching from non-activity context
            flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
          );

          // We don't have a direct "canResolve" check in this plugin easily,
          // so we attempt to launch. If it fails, the catch block handles it.
          await intent.launch();
          openedSpecificSettings = true;
          break; // It worked, stop trying
        } catch (e) {
          debugPrint("Failed to launch intent $path: $e");
          // Continue loop to try next path
        }
      }
    }

    // B. Fallback: If nothing opened, go to standard App Info
    if (!openedSpecificSettings) {
      debugPrint("Could not open OEM settings, opening standard App Details.");
      await _openStandardAppInfo();
    }
  }

  static Future<void> _openStandardAppInfo() async {
    // You need package_info_plus for this specific line:

    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final packageName = packageInfo.packageName;

    // For now, if you don't want the extra package, hardcode it:
    // const packageName = 'com.yourcompany.bluedrop'; // <--- CHANGE THIS

    final intent = AndroidIntent(
      action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
      data: 'package:$packageName',
    );
    await intent.launch();
  }
}
