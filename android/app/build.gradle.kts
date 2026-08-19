import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.isFile) {
    keystorePropertiesFile.inputStream().use(keystoreProperties::load)
}

fun releaseSigningValue(
    gradlePropertyName: String,
    keyPropertyName: String,
): String? =
    providers.gradleProperty(gradlePropertyName).orNull
        ?.trim()
        ?.takeIf { it.isNotEmpty() }
        ?: keystoreProperties.getProperty(keyPropertyName)
            ?.trim()
            ?.takeIf { it.isNotEmpty() }

val releaseStoreFile = releaseSigningValue("releaseStoreFile", "storeFile")
val releaseStorePassword =
    releaseSigningValue("releaseStorePassword", "storePassword")
val releaseKeyAlias = releaseSigningValue("releaseKeyAlias", "keyAlias")
val releaseKeyPassword =
    releaseSigningValue("releaseKeyPassword", "keyPassword")
val missingReleaseSigningProperties =
    mapOf(
        "releaseStoreFile" to releaseStoreFile,
        "releaseStorePassword" to releaseStorePassword,
        "releaseKeyAlias" to releaseKeyAlias,
        "releaseKeyPassword" to releaseKeyPassword,
    ).filterValues { it.isNullOrEmpty() }.keys

android {
    namespace = "com.holyquran.holy_quran_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.holyquran.holy_quran_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            releaseStoreFile?.let { storeFile = file(it) }
            storePassword = releaseStorePassword
            keyAlias = releaseKeyAlias
            keyPassword = releaseKeyPassword
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

val validateReleaseSigning by tasks.registering {
    group = "verification"
    description = "Validates the production Android release signing inputs."

    doLast {
        if (missingReleaseSigningProperties.isNotEmpty()) {
            throw GradleException(
                "Missing Android release signing properties: " +
                    missingReleaseSigningProperties.sorted().joinToString() +
                    ". Configure android/key.properties or protected CI Gradle project properties.",
            )
        }

        val keystoreFile = file(requireNotNull(releaseStoreFile))
        if (!keystoreFile.isFile) {
            throw GradleException(
                "Android release keystore not found at: ${keystoreFile.absolutePath}",
            )
        }
    }
}

tasks.configureEach {
    if (name == "preReleaseBuild") {
        dependsOn(validateReleaseSigning)
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
