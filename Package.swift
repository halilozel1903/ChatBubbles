// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ChatBubbles",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "ChatBubbles", targets: ["ChatBubbles"]),
    ],
    targets: [
        .target(name: "ChatBubbles"),
        .testTarget(name: "ChatBubblesTests", dependencies: ["ChatBubbles"]),
    ]
)
