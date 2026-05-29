// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DiskLeaner",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "DiskLeaner",
            path: "Sources/DiskLeaner"
        )
    ]
)
