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
            url: "https://github.com/InspireDevStdio/ExyteChat.git",
            exact: "1.0.2"
        ),
        .package(
            url: "https://github.com/socketio/socket.io-client-swift",
            exact: "16.1.1"
        )
    ],
    targets: [
        .target(
            name: "HeapchatSDKTarget",
            dependencies: [
                "HeapchatSDK",
                .product(name: "ExyteChat", package: "ExyteChat"),
                .product(name: "SocketIO", package: "socket.io-client-swift")
            ],
            path: "Sources"
        ),
        .binaryTarget(
            name: "HeapchatSDK",
            url: "https://github.com/InspireDevStdio/heap.chat_swift-sdk/releases/download/1.1.7/HeapchatSDK.xcframework.zip",
            checksum: "e8910e8ab3ab70f64d76195e73a8ddd8ddcca528cf510faa845b567aa7d740d8"
        ),
    ]
)
