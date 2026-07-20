// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MacClipbrd",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "MacClipbrd",
            path: "Sources/MacClipbrd"
        )
    ]
)
