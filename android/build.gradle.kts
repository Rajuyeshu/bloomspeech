allprojects {
    repositories {
        google()
        mavenCentral()
    }
    extra["compileSdkVersion"] = 36
    extra["targetSdkVersion"] = 36
    extra["minSdkVersion"] = 26
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

subprojects {
    fun configureAndroid() {
        val android = project.extensions.findByName("android")
        if (android != null) {
            try {
                val compileSdkVersionMethod = android::class.java.getMethod("compileSdkVersion", Int::class.javaPrimitiveType)
                compileSdkVersionMethod.invoke(android, 36)
            } catch (e: Exception) {
                try {
                    val compileSdkMethod = android::class.java.getMethod("setCompileSdk", java.lang.Integer::class.java)
                    compileSdkMethod.invoke(android, 36)
                } catch (e2: Exception) {}
            }
        }
    }

    if (project.state.executed) {
        configureAndroid()
    } else {
        project.afterEvaluate {
            configureAndroid()
        }
    }
}
