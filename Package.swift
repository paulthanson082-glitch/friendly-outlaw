// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WritersApp",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "WritersApp",
            targets: ["WritersApp"]),
        .executable(
            name: "WritersAppCLI",
            targets: ["WritersAppCLI"])
    ],
    targets: [
        .target(
            name: "WritersApp",
            dependencies: []),
        .executableTarget(
            name: "WritersAppCLI",
            dependencies: ["WritersApp"]),
        .testTarget(
            name: "WritersAppTests",
            dependencies: ["WritersApp"])
    ]
)
