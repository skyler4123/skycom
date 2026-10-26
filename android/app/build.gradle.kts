import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
}

// Override with: ./gradlew :app:assembleDebug -PskycomBaseUrl=http://10.0.2.2:3000
val skycomBaseUrl = providers.gradleProperty("skycomBaseUrl")
    .getOrElse("http://10.88.0.2:3000")
    .trimEnd('/')

android {
    namespace = "com.example.skycomandroid"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.example.skycomandroid"
        minSdk = 28
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"

        buildConfigField("String", "BASE_URL", "\"$skycomBaseUrl\"")
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    buildFeatures {
        buildConfig = true
    }
    packaging {
        resources {
            // OkHttp 5 and jspecify both ship this OSGI manifest.
            excludes += "META-INF/versions/9/OSGI-INF/MANIFEST.MF"
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

dependencies {
    implementation(libs.hotwire.native.core)
    implementation(libs.hotwire.native.navigation.fragments)
    implementation(libs.androidx.constraintlayout)
    implementation(libs.androidx.material)

    testImplementation(libs.junit)
    androidTestImplementation(libs.androidx.junit)
    androidTestImplementation(libs.androidx.espresso.core)
}
