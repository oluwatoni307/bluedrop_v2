plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.bluedrop_v2"
    
    // ✅ CRITICAL: flutter_local_notifications 20.0.0+ requires API 35
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // ✅ CRITICAL: Must be Java 17 for Desugaring 2.1.4+
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        
        // ✅ REQUIRED: Enable Core Library Desugaring
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        // ✅ CRITICAL: Must match Java version above
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.bluedrop_v2"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // ✅ RECOMMENDED: Prevents build errors when using Firebase + Desugaring
        multiDexEnabled = true 
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            // Note: If you add ProGuard later, configure it here.
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ Core Library Desugaring (REQUIRED for scheduled notifications)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    
    // ✅ Firebase dependencies
    implementation(platform("com.google.firebase:firebase-bom:34.8.0"))
    implementation("com.google.firebase:firebase-analytics")
    
    // Add other Firebase products here if needed
}