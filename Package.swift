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
            exact: "1.1.1"
        ),
        .package(
            url: "https://github.com/InspireDevStdio/ExyteMediaPicker",
            exact: "1.0.2"
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
            url: "https://github.com/InspireDevStdio/heapchat-swift-sdk/releases/download/1.2.16/HeapchatSDK.xcframework.zip",
            checksum: "951b3531dbd146cea2874608c3f2934ae736e8787e4267d93f394e554582a96e"
        ),
    ]
)
