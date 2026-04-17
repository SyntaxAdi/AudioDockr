plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.io.ByteArrayOutputStream
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

fun gitOutput(vararg args: String): String? {
    return runCatching {
        val stdout = ByteArrayOutputStream()
        exec {
            commandLine("git", *args)
            standardOutput = stdout
        }
        stdout.toString().trim().takeIf { it.isNotEmpty() }
    }.getOrNull()
}

val autoVersionCode = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyDDDHHmm")).toInt()
val gitSha = gitOutput("rev-parse", "--short", "HEAD") ?: "nogit"
val gitDirty = gitOutput("status", "--porcelain").isNullOrBlank().not()
val computedVersionName = buildString {
    append(gitSha)
    if (gitDirty) {
        append("-dirty")
    }
}

android {
    namespace = "com.akeno.audiodockr"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    buildFeatures {
        buildConfig = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.akeno.audiodockr"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = autoVersionCode
        versionName = computedVersionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.1")
    implementation("androidx.media3:media3-common:1.4.1")
    implementation("androidx.media3:media3-exoplayer:1.4.1")
    implementation("androidx.media3:media3-exoplayer-hls:1.4.1")
    implementation("androidx.media3:media3-session:1.4.1")
    implementation("androidx.media3:media3-ui:1.4.1")
    implementation("com.github.TeamNewPipe:NewPipeExtractor:v0.26.0")
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
}
