package come.deffcom.chatapp

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * Receives BOOT_COMPLETED (and Huawei/OnePlus QUICKBOOT_POWERON) to relaunch
 * Defcomm automatically after the device restarts. Works as-is on ODM devices
 * because the RECEIVE_BOOT_COMPLETED permission is already declared in the manifest.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (action == Intent.ACTION_BOOT_COMPLETED ||
            action == "android.intent.action.QUICKBOOT_POWERON" ||
            action == "com.htc.intent.action.QUICKBOOT_POWERON"
        ) {
            val launch = context.packageManager
                .getLaunchIntentForPackage(context.packageName)
            launch?.apply {
                addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TASK
                )
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    // On Android 10+ background activity starts are restricted;
                    // start as a foreground task to ensure it appears.
                    addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
                }
                context.startActivity(this)
            }
        }
    }
}
