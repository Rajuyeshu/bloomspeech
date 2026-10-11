import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing credentials, kept out of source control (see
// android/.gitignore). Create android/key.properties from
// key.properties.example, and generate the keystore with the keytool command
// documented there.
//
// Google Play rejects anything signed with the debug key, so a release build
// without this file is not publishable.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        load(FileInputStream(keystorePropertiesFile))
    }
}
val hasReleaseSigning = keystorePropertiesFile.exists()

android {
    // The code namespace, used for the generated R class and the Kotlin
    // package. It is deliberately NOT the applicationId: "in" is a reserved
    // keyword in Java and Kotlin, so `package in.bloomspeech.app` will not
    // compile. Gradle treats the two independently — Play only ever sees the
    // applicationId below.
    namespace = "app.bloomspeech"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // The app's permanent identity on Google Play. This CANNOT be changed
        // after the first release — a different value is a different app.
        applicationId = "in.bloomspeech.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Falls back to debug signing so `flutter run --release` still
            // works locally. A debug-signed bundle cannot be uploaded to Play;
            // run `./gradlew verifyReleaseSigning` before publishing.
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // Minification is deliberately OFF.
            //
            // Enabling it saved about 6% (160MB -> 150MB, since the bulk is
            // WebRTC native libraries that R8 does not touch) and introduced a
            // reflection failure in the app's own process — R8 had renamed a
            // class something was looking up by name. The video call and the
            // Supabase client both resolve things reflectively, and neither
            // can be verified without a live two-device session, so the saving
            // is not worth risking the most fragile parts of the app.
            //
            // Per-device download size is already handled by the App Bundle,
            // which ships only one ABI per device. proguard-rules.pro is kept
            // ready if this is revisited with time to test a real call.
            isMinifyEnabled = false
            isShrinkResources = false
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

// Catches the mistake that only shows up as a Play Console rejection: the
// build succeeds either way, so nothing otherwise tells you the debug key was
// used until after the upload is refused.
tasks.register("verifyReleaseSigning") {
    doLast {
        if (!hasReleaseSigning) {
            throw GradleException(
                "android/key.properties is missing, so release builds are " +
                "signed with the debug key and Google Play will reject them. " +
                "See android/key.properties.example."
            )
        }
        println("Release signing configured with alias " +
            "'${keystoreProperties["keyAlias"]}'.")
    }
}
