// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MGYavar",
    platforms: [.iOS(.v17)],
    targets: [
        .executableTarget(
            name: "MGYavar",
            path: "Sources",
            swiftSettings: [.define("SWIFTUI")]
        )
    ]
)
