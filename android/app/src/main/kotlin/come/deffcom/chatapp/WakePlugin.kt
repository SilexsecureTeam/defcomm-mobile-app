package come.deffcom.chatapp

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * A proper FlutterPlugin so that the wake-screen channel is registered in
 * BOTH the main Flutter engine AND the flutter_foreground_task background
 * isolate (via DartPluginRegistrant / GeneratedPluginRegistrant).
 *
 * This fixes the silent failure that occurred when the background isolate
 * called MethodChannel('come.deffcom.chatapp/oem_battery') — that channel
 * was only registered in MainActivity.configureFlutterEngine, which is
 * bound to the main engine only.
 */
class WakePlugin : FlutterPlugin, MethodCallHandler {

    private lateinit var channel: MethodChannel
    private lateinit var appContext: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "wakeScreen" -> {
                try {
                    // Send broadcast to WakeScreenReceiver — it acquires a
                    // SCREEN_BRIGHT_WAKE_LOCK | ACQUIRE_CAUSES_WAKEUP lock.
                    val intent = Intent("come.deffcom.chatapp.WAKE_SCREEN").apply {
                        setPackage(appContext.packageName)
                    }
                    appContext.sendBroadcast(intent)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("WAKE_FAILED", e.message, null)
                }
            }
            "canUseFullScreenIntent" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                    val nm = appContext.getSystemService(Context.NOTIFICATION_SERVICE)
                            as NotificationManager
                    result.success(nm.canUseFullScreenIntent())
                } else {
                    result.success(true) // always allowed below API 34
                }
            }
            "requestFullScreenIntentPermission" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                    try {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT
                        ).apply {
                            data = android.net.Uri.parse("package:${appContext.packageName}")
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        appContext.startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("OPEN_FAILED", e.message, null)
                    }
                } else {
                    result.success(true)
                }
            }
            else -> result.notImplemented()
        }
    }

    companion object {
        const val CHANNEL = "come.deffcom.chatapp/oem_battery"
    }
}
