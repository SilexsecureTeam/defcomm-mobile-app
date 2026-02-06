# ==============================
# 1. FLUTTER & DART CORE
# ==============================
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# 🔥 CRITICAL: Keep Background Service Entry Points
-keepnames class * {
    @dart.ui.pragma.vm.entry_point *;
}

# ==============================
# 2. BACKGROUND & NOTIFICATIONS
# ==============================
# Flutter Background Service
-keep class id.flutter.flutter_background_service.** { *; }
-keep public class * extends android.app.Service

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# ==============================
# 3. MESSAGING & CALLS
# ==============================
# Pusher Client
-keep class com.github.chinloyal.pusher_client.** { *; }
-keep class co.pusher.** { *; }
-dontwarn org.slf4j.impl.StaticLoggerBinder
-dontwarn org.slf4j.impl.**

# Flutter Callkit Incoming
-keep class com.hiennv.flutter_callkit_incoming.** { *; }
-keep class com.hiennv.flutter_callkit_incoming.CallkitIncomingPlugin { *; }

# ==============================
# 4. VIDEO SDK & WEBRTC (CRITICAL FOR CALLS)
# ==============================
-keep class live.videosdk.** { *; }
-keep class org.webrtc.** { *; }
-keep class com.cloudwebrtc.** { *; }

# ==============================
# 5. AUDIO & STORAGE
# ==============================
# Just Audio & Ringtone Player
-keep class com.ryanheise.just_audio.** { *; }
-keep class io.flutter.plugins.ur_ringtone_player.** { *; }

# GetStorage / SharedPrefs
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# EventBus & Gson (Common internal dependencies)
-keep class org.greenrobot.eventbus.** { *; }
-keep class com.google.gson.** { *; }

# ==============================
# 6. SUPPRESS WARNINGS
# ==============================
-dontwarn io.flutter.embedding.**
-dontwarn live.videosdk.**
-dontwarn org.webrtc.**