// swift-tools-version: 6.0
import PackageDescription

// Development-only conformance runner. Depends on the Swift SDK by path, so it
// always builds against the checked-out swift/Sources/Fizzy rather than a tag.
//
// The path goes through the FizzySDK symlink (-> ../../../swift) rather than
// naming ../../../swift directly: SwiftPM derives a package's identity from
// the last component of its directory, so a dependency on ".../swift" gets
// the identity "swift" — the same identity as this package, which also lives
// in a directory called "swift" — and is silently treated as a self-reference
// ("product 'Fizzy' ... not found"). The symlink gives the dependency its own
// identity without renaming either directory or adding a root manifest.
let package = Package(
    name: "ConformanceRunner",
    platforms: [
        .macOS(.v12)
    ],
    dependencies: [
        .package(name: "Fizzy", path: "FizzySDK")
    ],
    targets: [
        // Assertion contracts with no SDK dependency, split out of the
        // executable so their bounds branches can be unit-tested: a target
        // carrying @main cannot host a test bundle cleanly, and these branches
        // never execute against a fixture that passes.
        .target(
            name: "ConformanceSupport",
            path: "Sources/ConformanceSupport",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .executableTarget(
            name: "ConformanceRunner",
            dependencies: [
                .product(name: "Fizzy", package: "Fizzy"),
                "ConformanceSupport",
            ],
            path: "Sources/ConformanceRunner",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "ConformanceSupportTests",
            dependencies: [
                "ConformanceSupport"
            ],
            path: "Tests/ConformanceSupportTests",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
    ]
)
