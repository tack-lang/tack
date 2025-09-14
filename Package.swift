// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Tack",
    products: [
        .executable(name: "TackCLI", targets: ["TackCLI"]),
        .library(name: "TackLib", targets: ["TackLib"])
    ],
    dependencies: [
        .package(url: "https://github.com/onevcat/Rainbow.git", from: "4.0.0")
    ],
    targets: [
        .target(name: "TackLib", dependencies: [
            .product(name: "Rainbow", package: "Rainbow")
        ]),
        .executableTarget(
            name: "TackCLI",
            dependencies: [
                "TackLib",
                .product(name: "Rainbow", package: "Rainbow")
            ]
        ),
        .testTarget(name: "TackTests", dependencies: [
            "TackLib",
            .product(name: "Rainbow", package: "Rainbow")
        ])
    ]
)
