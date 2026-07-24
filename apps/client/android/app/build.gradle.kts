import java.util.Properties
import java.io.FileInputStream

plugins {
	id("com.android.application")
	// START: FlutterFire Configuration
	id("com.google.gms.google-services")
	// END: FlutterFire Configuration
	id("kotlin-android")
	// The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
	id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
	keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

	android {
	namespace = "com.gestion.v1"
	// Google Play: target API 36 (Android 16) obligatorio desde ago 2026.
	compileSdk = 36
	ndkVersion = "27.0.12077973"

	compileOptions {
		sourceCompatibility = JavaVersion.VERSION_11
		targetCompatibility = JavaVersion.VERSION_11
	}

	kotlinOptions {
		jvmTarget = JavaVersion.VERSION_11.toString()
	}

	defaultConfig {
		applicationId = "com.gestion.v1"
		// firebase_messaging requiere minSdk >= 23
		minSdk = 23
		targetSdk = 36
		versionCode = flutter.versionCode
		versionName = flutter.versionName
	}

	signingConfigs {
		create("release") {
			keyAlias = keystoreProperties["keyAlias"] as String
			keyPassword = keystoreProperties["keyPassword"] as String
			storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
			storePassword = keystoreProperties["storePassword"] as String
		}
	}

	buildTypes {
		release {
			signingConfig = signingConfigs.getByName("release")
		}
	}
}

flutter {
	source = "../.."
}
