// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "AMFlamingo",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "AMFlamingo",
            targets: ["AMFlamingo"]),
    ],
    dependencies: [
        .package(url: "https://github.com/SnapKit/SnapKit.git", from: "5.0.0")
    ],
    targets: [
        .target(
            name: "AMFlamingo",
            dependencies: ["SnapKit"],
            path: "Sources"),
        .testTarget(
            name: "AMFlamingoTests",
            dependencies: ["AMFlamingo"],
            path: "Tests"),
    ]
) 