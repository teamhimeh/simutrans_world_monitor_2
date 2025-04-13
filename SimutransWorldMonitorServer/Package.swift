// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SimutransWorldMonitorServer",
    platforms: [
        .macOS(.v13) // Minimum macOS version
    ],
    dependencies: [
        // Discord API wrapper - using DiscordBM as it's Swift-native and supports Swift concurrency
        .package(url: "https://github.com/DiscordBM/DiscordBM", from: "1.13.0"),
        // Swift Testing framework
        .package(url: "https://github.com/swiftlang/swift-testing", from: "0.1.0"),
    ],
    targets: [
        // Main executable target
        .executableTarget(
            name: "SimutransWorldMonitorServer",
            dependencies: [
                .product(name: "DiscordBM", package: "DiscordBM")
            ]),
        // Test target for unit testing
        .testTarget(
            name: "SimutransWorldMonitorServerTests",
            dependencies: [
                "SimutransWorldMonitorServer",
                .product(name: "Testing", package: "swift-testing")
            ]),
    ]
)
