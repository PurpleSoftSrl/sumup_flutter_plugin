// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "sumup",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "sumup", targets: ["sumup"])
    ],
    dependencies: [
        .package(url: "https://github.com/sumup/sumup-ios-sdk.git", from: "6.2.0"),
    ],
    targets: [
        .target(
            name: "sumup",
            dependencies: [
                .product(name: "SumUpSDK", package: "sumup-ios-sdk"),
            ],
            resources: []
        )
    ]
)
