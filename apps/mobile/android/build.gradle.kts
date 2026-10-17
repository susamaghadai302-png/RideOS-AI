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

subprojects {
    project.plugins.withId("com.android.library") {
        project.extensions.configure<com.android.build.gradle.LibraryExtension>("android") {
            compileSdk = 36
        }
    }
    if (!project.extensions.extraProperties.has("flutter")) {
        project.extensions.extraProperties.set(
            "flutter",
            mapOf(
                "compileSdkVersion" to 36,
                "minSdkVersion" to 21,
                "targetSdkVersion" to 36,
                "ndkVersion" to "28.2.13676358"
            )
        )
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
