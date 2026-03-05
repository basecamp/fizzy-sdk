// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Fizzy",
    platforms: [
        .iOS(.v16),
        .macOS(.v12),
    ],
    products: [
        .library(name: "Fizzy", targets: ["Fizzy"]),
    ],
    targets: [
        .target(
            name: "Fizzy",
            path: "Sources/Fizzy",
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .executableTarget(
            name: "FizzyGenerator",
            path: "Sources/FizzyGenerator",
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .testTarget(
            name: "FizzyTests",
            dependencies: ["Fizzy"],
            path: "Tests/FizzyTests",
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
    ]
)
