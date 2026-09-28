import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// The upload key Google Play knows this app by, named in android/key.properties
// (storeFile, relative to this directory; storePassword; keyAlias; keyPassword).
// Neither file is committed: the Play workflow writes both from secrets, and
// docs/shipping.md says where they came from. Without them a release build
// is signed with the debug key, as before — installable by hand, refused by
// Play — so the plain APK build keeps working with no secret at all.
val uploadKey = Properties()
val uploadKeyFile = rootProject.file("key.properties")
if (uploadKeyFile.exists()) {
    FileInputStream(uploadKeyFile).use { uploadKey.load(it) }
}

android {
    namespace = "com.juanluera.minihub"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Permanent from the first upload: Play, like App Store Connect, knows
        // the app by this string forever. The same one iOS uses.
        applicationId = "com.juanluera.minihub"
        minSdk = flutter.minSdkVersion
        // Play refuses an update that targets less than the API level it
        // currently requires, and Flutter's default follows it.
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (uploadKeyFile.exists()) {
            create("upload") {
                storeFile = file(uploadKey.getProperty("storeFile"))
                storePassword = uploadKey.getProperty("storePassword")
                keyAlias = uploadKey.getProperty("keyAlias")
                keyPassword = uploadKey.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig =
                if (uploadKeyFile.exists()) {
                    signingConfigs.getByName("upload")
                } else {
                    signingConfigs.getByName("debug")
                }
        }
    }
}

flutter {
    source = "../.."
}
