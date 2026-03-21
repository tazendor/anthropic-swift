// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "AnthropicKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "AnthropicKit",
            targets: ["AnthropicKit"],
        ),
    ],
    targets: [
        .target(
            name: "AnthropicKit",
        ),
        .testTarget(
            name: "AnthropicKitTests",
            dependencies: ["AnthropicKit"],
            resources: [
                .copy("Fixtures"),
            ],
        ),
    ],
)
