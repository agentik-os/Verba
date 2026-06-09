// swift-tools-version:6.0
import PackageDescription

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
        )
    ]
)
