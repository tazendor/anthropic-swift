// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "TazendorAnthropic",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "TazendorAnthropic",
            targets: ["TazendorAnthropic"],
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/tazendor/ai-swift.git",
            from: "0.1.0",
        ),
    ],
    targets: [
        .target(
            name: "TazendorAnthropic",
            dependencies: [
                .product(name: "TazendorAI", package: "ai-swift"),
            ],
        ),
        .testTarget(
            name: "TazendorAnthropicTests",
            dependencies: ["TazendorAnthropic"],
            resources: [
                .copy("Fixtures"),
            ],
        ),
    ],
)
