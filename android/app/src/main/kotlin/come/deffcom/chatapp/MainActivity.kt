package come.deffcom.chatapp

import android.app.ActivityManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.view.View
import android.view.WindowInsetsController
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val OEM_CHANNEL      = "come.deffcom.chatapp/oem_battery"
    private val LAUNCHER_CHANNEL  = "come.deffcom.chatapp/launcher"
    private val SETTINGS_CHANNEL  = "come.deffcom.chatapp/system_settings"

    // ── Kiosk helpers ──────────────────────────────────────────────────────
    private fun enterKioskMode() {
        try {
            // Keep screen on while app is in foreground
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            // NOTE: startLockTask() is intentionally removed — screen-pinning
            // mode forces Android to display the navigation bar (it is a system
            // security requirement and cannot be overridden), which conflicts
            // directly with hideSystemUI().  Full kiosk lock requires Device
            // Owner / MDM enrollment and is handled separately.
        } catch (_: Exception) {}
    }

    private fun hideSystemUI() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.insetsController?.let { ctrl ->
                ctrl.hide(
                    android.view.WindowInsets.Type.statusBars()
                            or android.view.WindowInsets.Type.navigationBars()
                )
                ctrl.systemBarsBehavior =
                    WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            }
        } else {
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                    or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                    or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                    or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                    or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                    or View.SYSTEM_UI_FLAG_FULLSCREEN
            )
        }
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        hideSystemUI()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) hideSystemUI()
    }

    override fun onStart() {
        super.onStart()
        enterKioskMode()
        hideSystemUI()  // Always AFTER enterKioskMode so it has the final word
    }

    override fun onResume() {
        super.onResume()
        enterKioskMode()
        hideSystemUI()  // Always AFTER enterKioskMode so it has the final word
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register WakePlugin as a proper FlutterPlugin so the main engine
        // has the wakeScreen / canUseFullScreenIntent / requestFullScreenIntentPermission
        // handlers via the v2 embedding API.
        flutterEngine.plugins.add(WakePlugin())

        // OEM battery settings channel — wakeScreen is now handled by WakePlugin
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, OEM_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openOemBatterySettings" -> {
                        val opened = tryOpenOemSettings()
                        if (!opened) {
                            try {
                                startActivity(
                                    Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                                        .apply { data = Uri.parse("package:$packageName") }
                                )
                            } catch (_: Exception) {
                                startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
                            }
                        }
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        // System settings channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SETTINGS_CHANNEL)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "openWifi" -> startActivity(Intent(Settings.ACTION_WIFI_SETTINGS))
                        "openBluetooth" -> startActivity(Intent(Settings.ACTION_BLUETOOTH_SETTINGS))
                        "openCamera" -> {
                            val cam = packageManager.getLaunchIntentForPackage("com.android.camera2")
                                ?: packageManager.getLaunchIntentForPackage("com.android.camera")
                                ?: Intent("android.media.action.STILL_IMAGE_CAMERA")
                            startActivity(cam)
                        }
                        else -> { result.notImplemented(); return@setMethodCallHandler }
                    }
                    result.success(true)
                } catch (e: Exception) {
                    result.error("UNAVAILABLE", e.message, null)
                }
            }

        // Launcher app drawer channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LAUNCHER_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startLockTask" -> {
                        enterKioskMode()
                        result.success(true)
                    }
                    "stopLockTask" -> {
                        try { stopLockTask() } catch (_: Exception) {}
                        result.success(true)
                    }
                    "getInstalledApps" -> {
                        val apps = getInstalledApps()
                        result.success(apps)
                    }
                    "launchApp" -> {
                        val packageName = call.argument<String>("packageName")
                        if (packageName != null) {
                            val launched = launchApp(packageName)
                            result.success(launched)
                        } else {
                            result.error("INVALID_ARGUMENT", "Package name is required", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /** Get list of all installed launchable apps */
    private fun getInstalledApps(): List<Map<String, String>> {
        val pm = packageManager
        val mainIntent = Intent(Intent.ACTION_MAIN, null).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }
        
        val apps = pm.queryIntentActivities(mainIntent, 0)
            .filter { it.activityInfo.packageName != packageName } // Exclude Defcomm itself
            .map { resolveInfo ->
                mapOf(
                    "name" to resolveInfo.loadLabel(pm).toString(),
                    "packageName" to resolveInfo.activityInfo.packageName
                )
            }
            .sortedBy { it["name"] }
        
        return apps
    }

    /** Launch an app by package name */
    private fun launchApp(packageName: String): Boolean {
        return try {
            val intent = packageManager.getLaunchIntentForPackage(packageName)
            if (intent != null) {
                startActivity(intent)
                true
            } else {
                false
            }
        } catch (_: Exception) {
            false
        }
    }

    /** Returns true if an OEM-specific settings screen was launched. */
    private fun tryOpenOemSettings(): Boolean {
        val mfr = Build.MANUFACTURER.lowercase()
        return try {
            val intent: Intent = when {
                mfr.contains("xiaomi") || mfr.contains("redmi") || mfr.contains("poco") ->
                    Intent().apply {
                        component = ComponentName(
                            "com.miui.securitycenter",
                            "com.miui.permcenter.autostart.AutoStartManagementActivity"
                        )
                    }
                mfr.contains("huawei") || mfr.contains("honor") ->
                    Intent().apply {
                        component = ComponentName(
                            "com.huawei.systemmanager",
                            "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"
                        )
                    }
                mfr.contains("oppo") ->
                    Intent().apply {
                        component = ComponentName(
                            "com.coloros.safecenter",
                            "com.coloros.safecenter.permission.startup.StartupAppListActivity"
                        )
                    }
                mfr.contains("realme") ->
                    Intent().apply {
                        component = ComponentName(
                            "com.realme.permissionmanager",
                            "com.realme.permissionmanager.ui.AppStartUpManageActivity"
                        )
                    }
                mfr.contains("vivo") ->
                    Intent().apply {
                        component = ComponentName(
                            "com.vivo.permissionmanager",
                            "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"
                        )
                    }
                mfr.contains("samsung") ->
                    Intent().apply {
                        component = ComponentName(
                            "com.samsung.android.lool",
                            "com.samsung.android.sm.ui.battery.BatteryActivity"
                        )
                    }
                mfr.contains("oneplus") ->
                    Intent().apply {
                        component = ComponentName(
                            "com.oneplus.security",
                            "com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity"
                        )
                    }
                mfr.contains("asus") ->
                    Intent().apply {
                        component = ComponentName(
                            "com.asus.mobilemanager",
                            "com.asus.mobilemanager.autostart.AutoStartActivity"
                        )
                    }
                else -> return false
            }
            startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }
}
