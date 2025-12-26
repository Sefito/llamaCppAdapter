// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LlamaCppAdapter",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "LlamaCppAdapter",
            targets: ["LlamaCppAdapter"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/ggerganov/llama.cpp.git", revision: "b6d6c5289f1c9c677657c380591201ddb210b649")
    ],
    targets: [
        // Swift adapter layer
        .target(
            name: "LlamaCppAdapter",
            dependencies: [
                .product(name: "llama", package: "llama.cpp")
            ],
            path: "Sources/LlamaCppAdapter",
            swiftSettings: [
                .interoperabilityMode(.Cxx)
            ]
        ),
        .testTarget(
            name: "LlamaCppAdapterTests",
            dependencies: ["LlamaCppAdapter"],
            path: "Tests/LlamaCppAdapterTests",
            swiftSettings: [
                .interoperabilityMode(.Cxx)
            ]
        ),
    ]
)
