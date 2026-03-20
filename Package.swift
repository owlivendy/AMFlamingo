// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "AMFlamingo",
    platforms: [
        .iOS(.v15)  // ⚠️ swift-markdown 最低要求 iOS 15
    ],
    products: [
        .library(
            name: "AMFlamingo",
            targets: ["AMFlamingo"]),
    ],
    dependencies: [
        .package(url: "https://github.com/SnapKit/SnapKit.git", from: "5.7.1"),
        // ✅ 添加 swift-markdown
        .package(url: "https://github.com/apple/swift-markdown.git", branch: "main")
    ],
    targets: [
        .target(
            name: "AMFlamingo",
            dependencies: [
                "SnapKit",
                // ✅ 引入 Markdown 模块
                .product(name: "Markdown", package: "swift-markdown")
            ],
            path: "Sources",
            resources: [
                .process("AMFlamingo/Resources")
            ]
        ),
        .testTarget(
            name: "AMFlamingoTests",
            dependencies: ["AMFlamingo"],
            path: "Tests"),
    ]
)