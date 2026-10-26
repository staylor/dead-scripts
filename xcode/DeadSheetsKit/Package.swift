// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "DeadSheetsKit",
    platforms: [.iOS(.v26), .macOS(.v26), .tvOS(.v26), .watchOS(.v26)],
    products: [
        .library(name: "DeadSheetsKit", targets: ["DeadSheetsKit"]),
    ],
    targets: [
        .target(
            name: "DeadSheetsKit",
            resources: [.copy("Resources/seeds.json")]
        ),
        .testTarget(
            name: "DeadSheetsKitTests",
            dependencies: ["DeadSheetsKit"]
        ),
    ]
)
