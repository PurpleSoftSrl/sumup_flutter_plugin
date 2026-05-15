plugins {
    id("com.android.library")
    id("kotlin-android")
}

val ttpAvailable = findProperty("SUMUP_TTP_MAVEN_USERNAME")?.toString()?.isNotBlank() == true
val ttpUser = if (ttpAvailable) findProperty("SUMUP_TTP_MAVEN_USERNAME")?.toString().orEmpty() else ""
val ttpPass = if (ttpAvailable) findProperty("SUMUP_TTP_MAVEN_PASSWORD")?.toString().orEmpty() else ""

rootProject.allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("https://maven.sumup.com/releases")
            content {
                includeGroupByRegex("com\\.sumup.*")
                includeGroup("net.sf.smc")
            }
        }
        if (ttpAvailable) {
            maven {
                url = uri("https://tap-to-pay-sdk.fleet.live.sumup.net/")
                content {
                    includeGroupByRegex("com\\.sumup.*")
                    includeGroup("ca.amadis.agnos")
                }
                credentials {
                    username = ttpUser
                    password = ttpPass
                }
            }
        }
    }
}

android {
    namespace = "io.purplesoft.sumup"

    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        minSdk = 30
        consumerProguardFiles("consumer-rules.pro")
    }

    sourceSets {
        getByName("main") {
            java.srcDirs(
                if (ttpAvailable) listOf("src/main/kotlin", "src/ttp/kotlin")
                else listOf("src/main/kotlin", "src/stub/kotlin")
            )
        }
    }

    lint {
        disable.add("InvalidPackage")
    }
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib:2.2.20")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2")
    implementation("com.google.android.gms:play-services-location:21.3.0")
    api("com.sumup:merchant-sdk:7.0.0")
    if (ttpAvailable) {
        implementation("com.sumup.tap-to-pay:utopia-sdk:1.0.6")
    }
}
