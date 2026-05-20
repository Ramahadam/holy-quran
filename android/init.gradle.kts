// Gradle init script to patch Isar namespace issue
allprojects {
    plugins.withId("com.android.library") {
        configure<com.android.build.gradle.LibraryExtension> {
            if (project.name == "isar_flutter_libs") {
                namespace = "dev.isar.isar_flutter_libs"
            }
        }
    }
}
