allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// ========== IMPORTANT ADDITIONS ==========

// Specify Kotlin version (required for some plugins)
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:7.3.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.0")
        classpath("com.google.gms:google-services:4.3.15") // For Firebase
    }
}

// This ensures all subprojects use the same Kotlin version
subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            android {
                compileSdkVersion(34) // or your desired version
                
                defaultConfig {
                    minSdkVersion(21)  // Minimum Android 5.0
                    targetSdkVersion(34)
                }
                
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_17
                    targetCompatibility = JavaVersion.VERSION_17
                }
                
                kotlinOptions {
                    jvmTarget = "17"
                }
            }
        }
    }
}