// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HeapchatFramework",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "HeapchatFramework",
            targets: ["HeapchatFrameworkTarget"]),
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
            name: "HeapchatFrameworkTarget",
            dependencies: [
                "HeapchatFramework",
                .product(name: "ExyteChat", package: "ExyteChat"),
                .product(name: "SocketIO", package: "socket.io-client-swift")
            ],
            path: "Sources"
        ),
        .binaryTarget(
            name: "HeapchatFramework",
            path: "../xcframework/.build/HeapchatFramework.xcframework"
        ),
    ]
)
