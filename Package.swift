// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HeapchatSDK",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "HeapchatSDK",
            targets: ["HeapchatSDKTarget"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/Giphy/giphy-ios-sdk",
            exact: "2.2.16"
        )
    ],
    targets: [
        .target(
            name: "HeapchatSDKTarget",
            dependencies: [
                "HeapchatSDK",
                .product(name: "GiphyUISDK", package: "giphy-ios-sdk")
            ],
            path: "Sources"
        ),
        .binaryTarget(
            name: "HeapchatSDK",
            url: "https://github.com/InspireDevStdio/heapchat-swift-sdk/releases/download/1.2.12/HeapchatSDK.xcframework.zip",
            checksum: "614788cab5faf3289789fe6caf7dda015f61c1f4b58ddd5462e11d7955b90c4f"
        ),
    ]
)
