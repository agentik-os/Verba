// swift-tools-version:6.0
import PackageDescription

// The updater contract suite (Tests/UpdaterContractTests.swift) is pure Foundation + XCTest: it
// reads local fixtures and repo files as data and depends on no product target. Declaring it
// standalone means `swift test` verifies the Sparkle feed/version contract WITHOUT building the
// app — and, on a non-Apple host, without WhisperKit/FluidAudio/Sparkle/AppKit, none of which
// exist there. So on macOS the package is the app plus the tests; anywhere else it is the tests
// alone, which is what makes the contract checkable from Linux CI.
let contractTests: Target = .testTarget(
    name: "UpdaterContractTests",
    path: "Tests",
    swiftSettings: [ .swiftLanguageMode(.v5) ]
)

#if os(macOS)

let package = Package(
    name: "Verba",
    platforms: [.macOS(.v14)],
    dependencies: [
        // Local, on-device transcription (Whisper large-v3-turbo on Apple Silicon).
        .package(url: "https://github.com/argmaxinc/WhisperKit.git", from: "0.9.0"),
        // Local, on-device transcription (NVIDIA Parakeet TDT v3, multilingual).
        .package(url: "https://github.com/FluidInference/FluidAudio.git", from: "0.12.4"),
        // Silent auto-updates.
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.0"),
    ],
    targets: [
        .executableTarget(
            name: "Verba",
            dependencies: [
                .product(name: "WhisperKit", package: "WhisperKit"),
                .product(name: "FluidAudio", package: "FluidAudio"),
                .product(name: "Sparkle", package: "Sparkle"),
            ],
            path: "Sources/Verba",
            swiftSettings: [ .swiftLanguageMode(.v5) ]
        ),
        // WidgetKit extension binary. Compiled by SwiftPM to an executable
        // (@main WidgetBundle), then assembled into VerbaWidget.appex and
        // embedded in Verba.app/Contents/PlugIns by bundle.sh.
        .executableTarget(
            name: "VerbaWidget",
            path: "Sources/VerbaWidget",
            swiftSettings: [ .swiftLanguageMode(.v5) ]
        ),
        contractTests,
    ]
)

#else

// Non-Apple host: only the contract tests. Dependencies are omitted deliberately — resolving
// three macOS-only packages to run an offline XML/version check would make `swift test` need
// network and a checkout it can never build.
let package = Package(
    name: "Verba",
    targets: [ contractTests ]
)

#endif
