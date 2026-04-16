plugins {
    alias(libs.plugins.kotlin.jvm)
    alias(libs.plugins.kotlin.serialization)
    application
}

application {
    mainClass.set("com.basecamp.fizzy.conformance.MainKt")
}

java {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

tasks.named<JavaExec>("run") {
    workingDir = rootProject.projectDir
}

dependencies {
    implementation(project(":fizzy-sdk"))
    implementation(libs.kotlinx.serialization.json)
    implementation(libs.ktor.client.mock)
    implementation(libs.kotlinx.coroutines.core)
}
