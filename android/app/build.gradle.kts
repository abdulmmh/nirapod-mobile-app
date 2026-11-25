plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseStore = providers.environmentVariable("ANDROID_KEYSTORE_PATH").orNull

android {
    signingConfigs {
        if (releaseStore != null) {
            create("upload") {
                storeFile = file(releaseStore)
                storePassword = providers.environmentVariable("ANDROID_KEYSTORE_PASSWORD").get()
                keyAlias = providers.environmentVariable("ANDROID_KEY_ALIAS").get()
                keyPassword = providers.environmentVariable("ANDROID_KEY_PASSWORD").get()
            }
        }
    }
    namespace = "com.vtms.nirapod.nirapod_mobile_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.vtms.nirapod.nirapod_mobile_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "environment"
    productFlavors {
        create("live") {
            manifestPlaceholders["appLabel"] = "Nirapod Flutter"
            dimension = "environment"
            manifestPlaceholders["allowHttp"] = "false"
        }
        create("local") {
            manifestPlaceholders["appLabel"] = "Nirapod Flutter (Local)"
            dimension = "environment"
            applicationIdSuffix = ".local"
            manifestPlaceholders["allowHttp"] = "true"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("upload")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
