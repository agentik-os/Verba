// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Verba",
    platforms: [.macOS(.v14)],
    dependencies: [
        // Local, on-device transcription (Whisper large-v3-turbo on Apple Silicon).
        .package(url: "https://github.com/argmaxinc/WhisperKit.git", from: "0.9.0"),
    ],
    targets: [
        .executableTarget(
            name: "Verba",
            dependencies: [
                .product(name: "WhisperKit", package: "WhisperKit"),
            ],
            path: "Sources/Verba",
            swiftSettings: [ .swiftLanguageMode(.v5) ]
        )
    ]
)
