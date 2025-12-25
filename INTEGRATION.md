# Integration Guide

This guide explains how to integrate llama.cpp C/C++ library with this Swift package.

## Current Status

This package provides a **complete Swift interface structure** designed following best practices for iOS development. The C/C++ integration layer is prepared but requires the actual llama.cpp library to be added.

## Adding llama.cpp

To complete the integration, you need to:

### Option 1: Add llama.cpp as a Submodule

```bash
git submodule add https://github.com/ggml-org/llama.cpp third-party/llama.cpp
```

Then update `Package.swift` to include the llama.cpp sources:

```swift
.target(
    name: "llama",
    dependencies: [],
    path: "third-party/llama.cpp",
    exclude: [
        "examples/",
        "tests/",
        "models/",
        // ... other non-essential directories
    ],
    sources: [
        "src/llama.cpp",
        "src/llama-vocab.cpp",
        "src/llama-grammar.cpp",
        "src/llama-sampling.cpp",
        "ggml/src/ggml.c",
        "ggml/src/ggml-alloc.c",
        "ggml/src/ggml-backend.c",
        "ggml/src/ggml-quants.c",
        "ggml/src/ggml-metal.m",  // For Metal support
    ],
    resources: [
        .process("ggml/src/ggml-metal.metal"),
    ],
    publicHeadersPath: "include",
    cSettings: [
        .define("GGML_USE_ACCELERATE"),
        .define("GGML_USE_METAL"),
        .headerSearchPath("include"),
        .headerSearchPath("ggml/include"),
    ],
    linkerSettings: [
        .linkedFramework("Accelerate"),
        .linkedFramework("Metal"),
        .linkedFramework("MetalKit"),
    ]
),
```

### Option 2: Use Pre-built XCFramework

Alternatively, build an XCFramework from llama.cpp:

```bash
# Build for iOS device
xcodebuild -project llama.xcodeproj \
  -scheme llama \
  -sdk iphoneos \
  -configuration Release \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES

# Build for iOS simulator
xcodebuild -project llama.xcodeproj \
  -scheme llama \
  -sdk iphonesimulator \
  -configuration Release \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES

# Create XCFramework
xcodebuild -create-xcframework \
  -framework path/to/iphoneos/llama.framework \
  -framework path/to/iphonesimulator/llama.framework \
  -output llama.xcframework
```

Then reference it in `Package.swift`:

```swift
.binaryTarget(
    name: "llama",
    path: "Frameworks/llama.xcframework"
)
```

## Implementing the C Bridge

The `llama_adapter.h` header is prepared. Implement the wrapper functions in a new file `llama_adapter.c`:

```c
#include "llama_adapter.h"
#include "llama.h"

void llama_adapter_backend_init(bool use_numa) {
    llama_backend_init();
    llama_numa_init(use_numa ? GGML_NUMA_STRATEGY_DISTRIBUTE : GGML_NUMA_STRATEGY_DISABLED);
}

void llama_adapter_backend_free(void) {
    llama_backend_free();
}

// Implement other wrapper functions...
```

## Connecting Swift to C

Update `LlamaRunner.swift` to call the C functions:

```swift
import Foundation

public final class LlamaRunner {
    private var modelPointer: OpaquePointer?
    private var contextPointer: OpaquePointer?
    
    public init(modelURL: URL, configuration: LlamaConfiguration) throws {
        // Initialize backend
        llama_adapter_backend_init(false)
        
        // Load model
        var modelParams = llama_adapter_model_params()
        modelParams.n_gpu_layers = configuration.useMetalAcceleration ? 99 : 0
        modelParams.n_threads = Int32(configuration.threads)
        
        guard let model = llama_adapter_load_model(
            modelURL.path.cString(using: .utf8),
            modelParams
        ) else {
            throw LlamaError.modelLoadFailed(reason: "Failed to load model")
        }
        
        self.modelPointer = model
        // ... continue implementation
    }
    
    // ... rest of implementation
}
```

## Metal Shader Integration

Ensure `ggml-metal.metal` is included in the package resources and properly loaded at runtime:

```swift
// In your initialization code
if configuration.useMetalAcceleration {
    guard let metalLib = Bundle.module.url(forResource: "ggml-metal", withExtension: "metal") else {
        throw LlamaError.metalNotAvailable
    }
    // Initialize Metal with the shader library
}
```

## Build Configuration

For optimal iOS builds, consider these compiler flags in `Package.swift`:

```swift
cSettings: [
    .define("GGML_USE_ACCELERATE"),
    .define("GGML_USE_METAL"),
    .define("NDEBUG", .when(configuration: .release)),
    .unsafeFlags([
        "-O3",
        "-ffast-math",
        "-funroll-loops",
    ], .when(configuration: .release)),
],
```

## Testing the Integration

Once integrated, test with:

```swift
let runner = try LlamaRunner(
    modelPath: "/path/to/small/model.gguf",
    configuration: .simulator
)

try await runner.loadModel()
let response = try await runner.generate(from: "Hello")
print(response.text)
```

## Common Issues

### Issue: Metal shaders not found
**Solution:** Ensure `ggml-metal.metal` is in the package resources and properly copied.

### Issue: Linking errors on simulator
**Solution:** Disable Metal for simulator builds in your configuration.

### Issue: Memory issues on device
**Solution:** Use smaller models or reduce context size in configuration.

## Next Steps

1. Add llama.cpp to the project using one of the methods above
2. Implement the C bridge functions
3. Update `LlamaRunner` to call the actual C API
4. Test with a small model
5. Optimize for your specific use case

## References

- [llama.cpp Examples](https://github.com/ggml-org/llama.cpp/tree/master/examples)
- [Swift C Interoperability](https://www.swift.org/documentation/cxx-interop/)
- [Metal Programming Guide](https://developer.apple.com/metal/)
