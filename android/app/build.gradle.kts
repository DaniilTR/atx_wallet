plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import org.gradle.api.GradleException

android {
    // Android package/namespace (must contain dots; do not use com.example for Play Console)
    namespace = "com.atx.wallet"
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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.atx.wallet"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Release signing is loaded from key.properties (Flutter default).
    // Fallback to keystore.properties for compatibility.
    // Never commit these files or the referenced .jks to VCS.
    val releaseSigningPropertiesFile =
        listOf(
                rootProject.file("key.properties"),
                rootProject.file("keystore.properties"),
            )
            .firstOrNull { it.exists() }

    val keystoreProperties = Properties()
    val hasReleaseKeystore = releaseSigningPropertiesFile != null
    if (hasReleaseKeystore) {
        releaseSigningPropertiesFile!!.inputStream().use { keystoreProperties.load(it) }
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                val keyAliasValue = keystoreProperties["keyAlias"] as String?
                val keyPasswordValue = keystoreProperties["keyPassword"] as String?
                val storePasswordValue = keystoreProperties["storePassword"] as String?
                val storeFileValue = keystoreProperties["storeFile"] as String?

                if (
                    keyAliasValue.isNullOrBlank() ||
                        keyPasswordValue.isNullOrBlank() ||
                        storePasswordValue.isNullOrBlank() ||
                        storeFileValue.isNullOrBlank()
                ) {
                    throw GradleException(
                        "Release signing properties are incomplete in ${releaseSigningPropertiesFile!!.name}. " +
                            "Required: storeFile, storePassword, keyAlias, keyPassword."
                    )
                }

                keyAlias = keyAliasValue
                keyPassword = keyPasswordValue
                storeFile = file(storeFileValue)
                storePassword = storePasswordValue
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseKeystore) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

dependencies {
    implementation("androidx.biometric:biometric:1.1.0")
    implementation("androidx.security:security-crypto:1.1.0")
}

flutter {
    source = "../.."
}
