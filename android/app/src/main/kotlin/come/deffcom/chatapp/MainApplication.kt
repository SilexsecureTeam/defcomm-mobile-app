package come.deffcom.chatapp

import android.app.Application

/**
 * Custom Application subclass required so Android resolves it via
 * android:name=".MainApplication" in the manifest.
 *
 * WakePlugin is registered in MainActivity.configureFlutterEngine for the
 * main engine.  The background isolate (flutter_foreground_task) relies on
 * FlutterCallkitIncoming's full-screen intent + the sendDataToMain → main
 * isolate → WakePlugin path to acquire the WakeLock.
 */
class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
    }
}
