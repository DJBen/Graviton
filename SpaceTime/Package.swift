// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "SpaceTime",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "SpaceTime",
            targets: ["SpaceTime"]),
    ],
    dependencies: [
        .package(path: "../MathUtil"),
    ],
    targets: [
        .target(
            name: "SpaceTime",
            dependencies: ["MathUtil"]),
        .testTarget(
            name: "SpaceTimeTests",
            dependencies: ["SpaceTime"]),
    ]
)
