// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "MathUtil",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "MathUtil",
            targets: ["MathUtil"]),
    ],
    dependencies: [
        // Dependencies go here
    ],
    targets: [
        .target(
            name: "MathUtil",
            dependencies: []),
        .testTarget(
            name: "MathUtilTests",
            dependencies: ["MathUtil"]),
    ]
)
