plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseKeystore = providers.environmentVariable("BLOCKADE_KEYSTORE_PATH").orNull

android {
    namespace = "com.carlospeter.blockade"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.carlospeter.blockade"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releaseKeystore != null) {
            create("production") {
                storeFile = file(releaseKeystore)
                storePassword = providers.environmentVariable("BLOCKADE_STORE_PASSWORD").get()
                keyAlias = providers.environmentVariable("BLOCKADE_KEY_ALIAS").get()
                keyPassword = providers.environmentVariable("BLOCKADE_KEY_PASSWORD").get()
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(
                if (releaseKeystore == null) "debug" else "production"
            )
        }
    }
}

flutter {
    source = "../.."
}
