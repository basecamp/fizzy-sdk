plugins {
    alias(libs.plugins.kotlin.jvm)
    alias(libs.plugins.kotlin.serialization)
    application
}

application {
    mainClass.set("com.basecamp.fizzy.conformance.MainKt")
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
