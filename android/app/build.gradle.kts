plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.defcomm"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // keep Java 11 compatibility
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11

        // ENABLE core library desugaring required by some libraries (e.g. flutter_local_notifications)
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID
        applicationId = "com.example.defcomm"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
    release {
        // Disable shrinking/minify for now to reduce work AAPT/R8 must do
        isMinifyEnabled = false
        isShrinkResources = false

        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro",
        )

        signingConfig = signingConfigs.getByName("debug")
    }
}

}

dependencies {
    // Add core library desugaring implementation
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")


    // Keep any other dependencies the Flutter plugin injects; if you already have implementation lines,
    // do not remove them. This file is intentionally minimal; Gradle will add the Flutter SDK dependencies.
}

flutter {
    source = "../.."
}
