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
        .library(
            name: "WritersAppIOS",
            targets: ["WritersAppIOS"]),
        .executable(
            name: "WritersAppCLI",
            targets: ["WritersAppCLI"])
    ],
    targets: [
        .systemLibrary(
            name: "CSQLite",
            pkgConfig: "sqlite3"),
        .target(
            name: "WritersApp",
            dependencies: ["CSQLite"]),
        .executableTarget(
            name: "WritersAppCLI",
            dependencies: ["WritersApp"]),
        .target(
            name: "WritersAppIOS",
            dependencies: ["WritersApp"]),
        .testTarget(
            name: "WritersAppTests",
            dependencies: ["WritersApp"])
    ]
)
