package come.deffcom.chatapp

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.PowerManager

/**
 * Receives a local broadcast to wake the screen.
 *
 * The WS foreground task handler runs in a **background isolate** and cannot
 * invoke the Flutter MethodChannel on the main isolate when the app is
 * suspended by Android.  This receiver listens for a native broadcast
 * (come.deffcom.chatapp.WAKE_SCREEN) and acquires a SCREEN_BRIGHT_WAKE_LOCK
 * directly — no Flutter isolate needed.
 */
class WakeScreenReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != "come.deffcom.chatapp.WAKE_SCREEN") return
        try {
            val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            @Suppress("DEPRECATION")
            val wl = pm.newWakeLock(
                PowerManager.SCREEN_BRIGHT_WAKE_LOCK
                    or PowerManager.ACQUIRE_CAUSES_WAKEUP
                    or PowerManager.ON_AFTER_RELEASE,
                "defcomm:wakeScreenBR"
            )
            wl.acquire(10_000L) // hold for 10 seconds then auto-release
        } catch (e: Exception) {
            android.util.Log.e("WakeScreenReceiver", "wakeScreen failed: ${e.message}")
        }
    }
}
