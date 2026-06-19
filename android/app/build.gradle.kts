plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.siapp.acceso"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
        // 👇 Suprime warnings comunes de Kotlin: deprecados, no usados, APIs experimentales
        freeCompilerArgs = listOf(
            "-Xlint:-unused",
            "-Xlint:-deprecation",
            "-Xopt-in=kotlin.RequiresOptIn"
        )
    }

    defaultConfig {
        applicationId = "com.siapp.acceso"
        minSdk = 21
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // 👇 Suprime warnings de Lint más comunes (especialmente útiles en Flutter)
    lint {
        checkReleaseBuilds = false
        abortOnError = false
        disable += listOf(
            "ObsoleteLintCustomCheck",
            "GradleDeprecated",
            "DeprecatedApi",
            "MissingTranslation",
            "GoogleAppIndexingWarning",
            "UnusedResources",
            "InvalidPackage"
        )
    }
}

// 👇 Suprime warnings del compilador Java (deprecation, unchecked, etc.)
tasks.withType<JavaCompile> {
    options.compilerArgs.addAll(
        listOf(
            "-Xlint:-deprecation",
            "-Xlint:-unchecked"
            // "-nowarn" // ⚠️ Solo si quieres suprimir TODOS los warnings de Java (no recomendado)
        )
    )
}

flutter {
    source = "../.."
}