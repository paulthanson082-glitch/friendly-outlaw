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
        .systemLibrary(
            name: "CSQLite",
            pkgConfig: "sqlite3",
            providers: [
                .brew(["sqlite3"]),
                .apt(["libsqlite3-dev"]),
                .yum(["sqlite-devel"])
            ]),
        .target(
            name: "WritersApp",
            dependencies: ["CSQLite"]),
        .executableTarget(
            name: "WritersAppCLI",
            dependencies: ["WritersApp"]),
        .testTarget(
            name: "WritersAppTests",
            dependencies: ["WritersApp"])
    ]
)
