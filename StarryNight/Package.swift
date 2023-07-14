// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "StarryNight",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "StarryNight",
            targets: ["StarryNight"]),
    ],
    dependencies: [
        .package(path: "../MathUtil"),
        .package(path: "../SpaceTime"),
        .package(
            url: "https://github.com/stephencelis/SQLite.swift",
            from: Version(0, 14, 1)
        ),
        .package(
            url: "https://github.com/SwiftyBeaver/SwiftyBeaver",
            from: Version(2, 0, 0)
        ),
        .package(
            url: "https://github.com/sharplet/Regex",
            from: Version(2, 0, 0)
        ),
        .package(
            url: "https://github.com/AlexanderTar/LASwift",
            from: Version(0, 3, 2)
        ),
        .package(
              url: "https://github.com/apple/swift-collections",
              from: Version(1, 0, 0)
        ),
    ],
    targets: [
        .target(
            name: "StarryNight",
            dependencies: [
                "MathUtil",
                .product(name: "Regex", package: "Regex"),
                "SpaceTime",
                .product(name: "SQLite", package: "SQLite.swift"),
                "SwiftyBeaver",
                "LASwift",
                .product(name: "Collections", package: "swift-collections")
            ],
            path: "Sources",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "StarryNightTests",
            dependencies: ["StarryNight"],
            path: "Tests",
            resources: [
                .process("Resources")
            ]
        ),
    ]
)
