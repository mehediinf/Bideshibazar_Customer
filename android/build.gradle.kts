import com.android.build.gradle.LibraryExtension
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = file("../build")

subprojects {
    project.buildDir = file("${rootProject.buildDir}/${project.name}")
}

subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    plugins.withId("com.android.library") {
        extensions.configure<LibraryExtension>("android") {
            if (namespace.isNullOrBlank()) {
                val manifestFile = project.file("src/main/AndroidManifest.xml")
                if (manifestFile.exists()) {
                    val match = Regex("package\\s*=\\s*\"([^\"]+)\"")
                        .find(manifestFile.readText())
                    val manifestPackage = match?.groupValues?.getOrNull(1)
                    if (!manifestPackage.isNullOrBlank()) {
                        namespace = manifestPackage
                    }
                }
            }
        }
    }
}

subprojects {
    if (name == "image_gallery_saver") {
        plugins.withId("com.android.library") {
            extensions.configure<LibraryExtension>("android") {
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_1_8
                    targetCompatibility = JavaVersion.VERSION_1_8
                }
            }
        }

        tasks.withType(KotlinCompile::class.java).configureEach {
            kotlinOptions.jvmTarget = "1.8"
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
