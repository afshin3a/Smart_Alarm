import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory

// ✅ تنظیم مخازن
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ✅ تنظیم مسیر build جدید برای کل پروژه (اختیاری ولی مفید)
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

// ✅ تنظیم مسیر build جدید برای زیرپروژه‌ها
subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// ✅ تضمین اینکه زیرپروژه‌ها اول ارزیابی شوند
subprojects {
    project.evaluationDependsOn(":app")
}

// ✅ تسک clean برای پاک‌سازی فایل‌های build
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
