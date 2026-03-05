rootProject.name = "fizzy-sdk-kotlin"

dependencyResolutionManagement {
    repositories {
        mavenCentral()
    }
}

include(":fizzy-sdk")
project(":fizzy-sdk").projectDir = file("sdk")
include(":generator")
include(":conformance")
