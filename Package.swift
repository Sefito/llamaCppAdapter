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
        // Add llama.cpp as a dependency when ready
        // For now, we'll structure the package to accept it
    ],
    targets: [
        .target(
            name: "LlamaCppAdapter",
            dependencies: [],
            path: "Sources/LlamaCppAdapter",
            publicHeadersPath: "include",
            cSettings: [
                .define("GGML_USE_ACCELERATE"),
                .define("GGML_USE_METAL"),
                .define("GGML_USE_BLAS"),
                .headerSearchPath("include"),
            ],
            cxxSettings: [
                .define("GGML_USE_ACCELERATE"),
                .define("GGML_USE_METAL"),
            ],
            swiftSettings: [
                .interoperabilityMode(.Cxx)
            ],
            linkerSettings: [
                .linkedFramework("Accelerate"),
                .linkedFramework("Metal"),
                .linkedFramework("MetalKit"),
                .linkedFramework("MetalPerformanceShaders"),
                .linkedFramework("Foundation"),
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
    ],
    cxxLanguageStandard: .cxx17
)
