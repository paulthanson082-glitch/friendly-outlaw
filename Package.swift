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
            targets: ["WritersAppCLI"]),
        .executable(
            name: "StatuslineCounter",
            targets: ["StatuslineCounter"])
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
        .executableTarget(
            name: "StatuslineCounter",
            dependencies: ["CSQLite"]),
        .testTarget(
            name: "WritersAppTests",
            dependencies: ["WritersApp"])
    ]
)
