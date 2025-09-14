// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Tack",
    dependencies: [
        .package(url: "https://github.com/onevcat/Rainbow.git", from: "4.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "Tack",
            dependencies: [
                .product(name: "Rainbow", package: "Rainbow")
            ]
        ),
        .testTarget(name: "TackTest", dependencies: ["Tack"], path: "Tests/TackTests", exclude: ["../Sources/main.swift"]),
    ]
)
