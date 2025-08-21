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
            url: "https://github.com/InspireDevStdio/heap.chat_swift-sdk/releases/download/1.1.8/HeapchatSDK.xcframework.zip",
            checksum: "95e542af92eeaff896a45ca2605fc18b83ca84a6d41a19060f5aa2b86b4df4ff"
        ),
    ]
)
