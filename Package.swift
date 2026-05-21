// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HeapchatSDK",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "HeapchatSDK",
            targets: ["HeapchatSDK"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/InspireDevStdio/ExyteChat.git",
            exact: "1.1.2"
        ),
        .package(
            url: "https://github.com/InspireDevStdio/ExyteMediaPicker",
            exact: "1.0.5"
        ),
        .package(
            url: "https://github.com/InspireDevStdio/ExyteActivityIndicator",
            exact: "1.0.0"
        ),
        .package(
            url: "https://github.com/socketio/socket.io-client-swift",
            exact: "16.1.1"
        )
    ],
    targets: [
        .target(
            name: "HeapchatSDK",
            dependencies: [
                .product(name: "ExyteChat", package: "ExyteChat"),
                .product(name: "ExyteMediaPicker", package: "ExyteMediaPicker"),
                .product(name: "ExyteActivityIndicator", package: "ExyteActivityIndicator"),
                .product(name: "SocketIO", package: "socket.io-client-swift")
            ],
            path: "Sources/HeapchatSDK"
        ),
    ]
)
