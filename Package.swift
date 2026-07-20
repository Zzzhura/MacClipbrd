// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Multibuf",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Multibuf",
            path: "Sources/Multibuf"
        )
    ]
)
