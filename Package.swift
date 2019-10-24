// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NetworkKit",
	platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "NetworkKit",
            targets: ["NetworkKit"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "NetworkKit",
            dependencies: [])
    ]
)
