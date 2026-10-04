// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WritersApp",
    platforms: [
        .macOS(.v14),
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "WritersApp",
            targets: ["WritersApp"]),
        .executable(
            name: "WritersAppCLI",
            targets: ["WritersAppCLI"]),
        .library(
            name: "MockerKit",
            targets: ["MockerKit"]),
        .executable(
            name: "mocker",
            targets: ["Mocker"]),
        .executable(
            name: "manop",
            targets: ["ManpageOperator"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0")
    ],
    targets: [
        // WritersApp targets
        .systemLibrary(
            name: "CSQLite",
            pkgConfig: "sqlite3"),
        .target(
            name: "WritersApp",
            dependencies: ["CSQLite"]),
        .executableTarget(
            name: "WritersAppCLI",
            dependencies: ["WritersApp"]),
        .testTarget(
            name: "WritersAppTests",
            dependencies: ["WritersApp"]),

        // Mocker targets
        .target(
            name: "MockerKit",
            dependencies: [
                .product(name: "Yams", package: "Yams")
            ]),
        .executableTarget(
            name: "Mocker",
            dependencies: [
                "MockerKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]),
        .testTarget(
            name: "MockerKitTests",
            dependencies: ["MockerKit"]),

        // ManpageOperator target
        .executableTarget(
            name: "ManpageOperator",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ])
    ]
)
