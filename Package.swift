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
        ),
        .package(
            url: "https://github.com/InspireDevStdio/ExyteChat",
            exact: "1.1.3"
        ),
        .package(
            url: "https://github.com/InspireDevStdio/ExyteMediaPicker",
            exact: "1.0.6"
        )
    ],
    targets: [
        .target(
            name: "HeapchatSDKTarget",
            dependencies: [
                "HeapchatSDK",
                .product(name: "GiphyUISDK", package: "giphy-ios-sdk"),
                .product(name: "ExyteChat", package: "ExyteChat"),
                .product(name: "ExyteMediaPicker", package: "ExyteMediaPicker")
            ],
            path: "Sources"
        ),
        .binaryTarget(
            name: "HeapchatSDK",
            url: "https://github.com/InspireDevStdio/heapchat-swift-sdk/releases/download/1.2.19/HeapchatSDK.xcframework.zip",
            checksum: "db86b1ca2cd11619869d70c6e3f2728e80037f4ede5ec1af5a6c2e4baec18a15"
        ),
    ]
)
