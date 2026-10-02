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
            url: "https://github.com/InspireDevStdio/heapchat-swift-sdk/releases/download/1.2.18/HeapchatSDK.xcframework.zip",
            checksum: "c0c67dc6857761f518543fec25a98c809bcaf4b727bb595ce8e8e270aeb7bc85"
        ),
    ]
)
