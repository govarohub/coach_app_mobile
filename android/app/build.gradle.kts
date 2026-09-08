import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")

    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration

    // El plugin de Flutter debe aplicarse después de Android/Kotlin.
    id("dev.flutter.flutter-gradle-plugin")
}

// ---------------------------------------------------------------------------
// Configuración de firma Release.
//
// Las contraseñas y el alias se mantienen fuera de este archivo.
// Se leen desde android/key.properties.
//
// IMPORTANTE:
// key.properties está incluido en .gitignore y no debe subirse al repositorio.
// ---------------------------------------------------------------------------

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.govarohub.coach"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.govarohub.coach"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // -----------------------------------------------------------------------
    // Configuración de la clave utilizada para firmar Release.
    // -----------------------------------------------------------------------

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")

            storeFile = keystoreProperties.getProperty("storeFile")?.let {
                file(it)
            }

            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        release {
            // Release utiliza nuestra upload keystore.
            // Ya NO utiliza la clave Debug.
            signingConfig = signingConfigs.getByName("release")
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