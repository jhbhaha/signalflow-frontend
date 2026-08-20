// File: build.gradle.kts (Android 앱 Gradle 설정)
// Last Modified: 2026-07-22 07:41 KST
// Insert Location: G:\03. flutter\stockmarket_frontend\android\app\build.gradle.kts 전체 교체
// [2026-07-22 07:41 KST] Google Play Android 16(API 36) 정책 대응

import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.signalflow.stock"
    // [2026-07-22 07:41 KST]
    // Google Play Android 16(API 36) 정책 대응
    compileSdk = 36

    ndkVersion = "27.0.12077973"

    compileOptions {
        // flutter_local_notifications 등 최신 플러그인 호환을 위한 desugaring 활성화
        // (Enable desugaring for modern Android plugin compatibility)
        isCoreLibraryDesugaringEnabled = true

        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.signalflow.stock"
        minSdk = flutter.minSdkVersion
        // [2026-07-22 07:41 KST]
        // Google Play Android 16(API 36) 정책 대응
        targetSdk = 36

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}