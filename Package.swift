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
    dependencies: [],
    targets: [
        // llama.cpp C/C++ library target
        .target(
            name: "llama",
            dependencies: [],
            path: "third-party/llama.cpp",
            exclude: [
                "examples",
                "tests",
                "models",
                "prompts",
                "grammars",
                "scripts",
                "ci",
                ".github",
                ".devops",
                "common",
                "pocs",
                "ggml/src/ggml-cuda",
                "ggml/src/ggml-sycl",
                "ggml/src/ggml-vulkan",
                "ggml/src/ggml-kompute",
                "ggml/src/ggml-rpc",
                "ggml/src/ggml-cann",
                "ggml/src/ggml-hip",
                "src/models",  // Exclude model architectures - include only what's needed
            ],
            sources: [
                "src/llama.cpp",
                "src/llama-adapter.cpp",
                "src/llama-arch.cpp",
                "src/llama-batch.cpp",
                "src/llama-chat.cpp",
                "src/llama-context.cpp",
                "src/llama-cparams.cpp",
                "src/llama-grammar.cpp",
                "src/llama-graph.cpp",
                "src/llama-hparams.cpp",
                "src/llama-impl.cpp",
                "src/llama-io.cpp",
                "src/llama-kv-cache.cpp",
                "src/llama-kv-cache-iswa.cpp",
                "src/llama-memory.cpp",
                "src/llama-memory-hybrid.cpp",
                "src/llama-memory-recurrent.cpp",
                "src/llama-mmap.cpp",
                "src/llama-model.cpp",
                "src/llama-model-loader.cpp",
                "src/llama-model-saver.cpp",
                "src/llama-quant.cpp",
                "src/llama-sampling.cpp",
                "src/llama-vocab.cpp",
                "src/unicode.cpp",
                "src/unicode-data.cpp",
                "ggml/src/ggml.c",
                "ggml/src/ggml.cpp",
                "ggml/src/ggml-alloc.c",
                "ggml/src/ggml-backend.cpp",
                "ggml/src/ggml-backend-reg.cpp",
                "ggml/src/ggml-quants.c",
                "ggml/src/ggml-opt.cpp",
                "ggml/src/ggml-threading.cpp",
                "ggml/src/gguf.cpp",
                // Metal support
                "ggml/src/ggml-metal/ggml-metal.cpp",
                "ggml/src/ggml-metal/ggml-metal-ops.cpp",
                "ggml/src/ggml-metal/ggml-metal-device.cpp",
                "ggml/src/ggml-metal/ggml-metal-device.m",
                "ggml/src/ggml-metal/ggml-metal-context.m",
                "ggml/src/ggml-metal/ggml-metal-common.cpp",
            ],
            resources: [
                .process("ggml/src/ggml-metal/ggml-metal.metal"),
            ],
            publicHeadersPath: "include",
            cSettings: [
                .define("GGML_USE_ACCELERATE"),
                .define("GGML_USE_METAL"),
                .define("GGML_SWIFT"),
                .headerSearchPath("include"),
                .headerSearchPath("src"),
                .headerSearchPath("ggml/include"),
                .headerSearchPath("ggml/src"),
                .headerSearchPath("ggml/src/ggml-metal"),
                .unsafeFlags(["-Wno-shorten-64-to-32"], .when(configuration: .release)),
            ],
            cxxSettings: [
                .define("GGML_USE_ACCELERATE"),
                .define("GGML_USE_METAL"),
                .define("GGML_SWIFT"),
                .headerSearchPath("include"),
                .headerSearchPath("src"),
                .headerSearchPath("ggml/include"),
                .headerSearchPath("ggml/src"),
                .headerSearchPath("ggml/src/ggml-metal"),
            ],
            linkerSettings: [
                .linkedFramework("Accelerate"),
                .linkedFramework("Metal"),
                .linkedFramework("MetalKit"),
                .linkedFramework("Foundation"),
            ]
        ),
        // Swift adapter layer
        .target(
            name: "LlamaCppAdapter",
            dependencies: ["llama"],
            path: "Sources/LlamaCppAdapter",
            publicHeadersPath: "include",
            cSettings: [
                .define("GGML_USE_ACCELERATE"),
                .define("GGML_USE_METAL"),
                .headerSearchPath("include"),
                .headerSearchPath("../../third-party/llama.cpp/include"),
                .headerSearchPath("../../third-party/llama.cpp/ggml/include"),
                .headerSearchPath("../../third-party/llama.cpp/src"),
            ],
            cxxSettings: [
                .define("GGML_USE_ACCELERATE"),
                .define("GGML_USE_METAL"),
                .headerSearchPath("include"),
                .headerSearchPath("../../third-party/llama.cpp/include"),
                .headerSearchPath("../../third-party/llama.cpp/ggml/include"),
                .headerSearchPath("../../third-party/llama.cpp/src"),
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
