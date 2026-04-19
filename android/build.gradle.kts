plugins {
    id("com.android.application") version "8.6.1" apply false
    id("org.jetbrains.kotlin.android") version "1.9.25" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    afterEvaluate {
        val androidExtension = extensions.findByName("android") ?: return@afterEvaluate
        val getNamespace = androidExtension::class.java.methods
            .firstOrNull { it.name == "getNamespace" && it.parameterCount == 0 }
        val setNamespace = androidExtension::class.java.methods
            .firstOrNull { it.name == "setNamespace" && it.parameterCount == 1 }

        if (getNamespace == null || setNamespace == null) {
            return@afterEvaluate
        }

        val currentNamespace = getNamespace.invoke(androidExtension) as? String
        if (!currentNamespace.isNullOrBlank()) {
            return@afterEvaluate
        }

        val manifestFile = project.file("src/main/AndroidManifest.xml")
        if (!manifestFile.exists()) {
            return@afterEvaluate
        }

        val manifestText = manifestFile.readText()
        val packageName = Regex("package=\"([^\"]+)\"")
            .find(manifestText)
            ?.groupValues
            ?.getOrNull(1)

        if (!packageName.isNullOrBlank()) {
            setNamespace.invoke(androidExtension, packageName)
        }
    }
}

