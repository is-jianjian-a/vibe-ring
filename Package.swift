// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "VibeRing",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "VibeRingCore",
            targets: ["VibeRingCore"]
        ),
        .executable(
            name: "VibeRingHooks",
            targets: ["VibeRingHooks"]
        ),
        .executable(
            name: "VibeRingSetup",
            targets: ["VibeRingSetup"]
        ),
        .executable(
            name: "VibeRingApp",
            targets: ["VibeRingApp"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "2.4.1"),
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.9.0"),
    ],
    targets: [
        .target(
            name: "VibeRingCore"
        ),
        .executableTarget(
            name: "VibeRingHooks",
            dependencies: ["VibeRingCore"]
        ),
        .executableTarget(
            name: "VibeRingSetup",
            dependencies: ["VibeRingCore"]
        ),
        .executableTarget(
            name: "VibeRingApp",
            dependencies: [
                "VibeRingCore",
                .product(name: "MarkdownUI", package: "swift-markdown-ui"),
                .product(name: "Sparkle", package: "Sparkle"),
            ],
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "VibeRingCoreTests",
            dependencies: ["VibeRingCore"]
        ),
        .testTarget(
            name: "VibeRingAppTests",
            dependencies: ["VibeRingApp", "VibeRingCore"]
        ),
    ]
)
