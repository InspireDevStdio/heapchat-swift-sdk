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
            branch: "old"
        ),
        .package(
            url: "https://github.com/socketio/socket.io-client-swift",
            from: "16.1.1"
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
            url: "https://github.com/InspireDevStdio/heap.chat_swift-sdk/releases/download/1.0.9/HeapchatSDK.xcframework.zip",
            checksum: "8a70a0e1cdc6720369d9e9c73052c8946a39b2282afe4ec78baeb357598b4afb"
        ),
    ]
)
