
// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Puller",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(
            name: "Puller",
            targets: ["Puller"])
    ],
    targets: [
        .target(
            name: "Puller",
            dependencies: [],
            path: "Sources/"),
    ]
)
