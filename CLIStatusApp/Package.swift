// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "CLIStatusApp",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "CLIStatusApp", targets: ["CLIStatusApp"])
    ],
    targets: [
        .executableTarget(
            name: "CLIStatusApp",
            path: "CLIStatusApp"
        )
    ]
)
