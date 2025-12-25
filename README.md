# LlamaCppAdapter

A Swift Package for integrating [llama.cpp](https://github.com/ggml-org/llama.cpp) with iOS and macOS applications. This adapter provides a clean, Swift-native interface for running large language models locally on Apple devices, with full support for iOS Simulator testing.

## Features

- 🚀 **Native Swift API** - Clean, idiomatic Swift interface with async/await support
- 🎯 **iOS Simulator Support** - Test your models in the simulator before deploying
- ⚡ **Metal Acceleration** - Leverage Apple's GPU for fast inference on physical devices
- 🔄 **Streaming Output** - Real-time token generation with AsyncStream
- 🎛️ **Flexible Configuration** - Pre-configured presets and customizable parameters
- 📱 **Device-Optimized** - Automatic configuration based on device capabilities
- 🛡️ **Type-Safe** - Comprehensive error handling with Swift error types
- 📦 **Swift Package Manager** - Easy integration with SPM

## Requirements

- iOS 14.0+ / macOS 11.0+
- Xcode 14.0+
- Swift 5.9+

## Installation

### Swift Package Manager

Add LlamaCppAdapter to your project using Xcode:

1. File → Add Packages...
2. Enter the repository URL: `https://github.com/Sefito/llamaCppAdapter`
3. Select the version you want to use

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Sefito/llamaCppAdapter", from: "1.0.0")
]
```

## Quick Start

### Basic Usage

```swift
import LlamaCppAdapter

// Initialize the runner with a model file
let runner = try LlamaRunner(modelPath: "/path/to/model.gguf")

// Load the model
try await runner.loadModel()

// Generate text
let response = try await runner.generate(from: "Once upon a time")
print("Generated: \(response.text)")
print("Speed: \(response.tokensPerSecond) tokens/sec")

// Clean up
runner.unloadModel()
```

### Streaming Generation

```swift
let runner = try LlamaRunner(modelPath: "/path/to/model.gguf")
try await runner.loadModel()

// Stream tokens as they're generated
for try await token in runner.run(with: "Tell me a story") {
    print(token.text, terminator: "")
}
```

### Custom Configuration

```swift
let config = LlamaConfiguration(
    threads: 4,
    maxTokens: 256,
    temperature: 0.8,
    topP: 0.95,
    contextSize: 2048,
    useMetalAcceleration: true
)

let runner = try LlamaRunner(
    modelPath: "/path/to/model.gguf",
    configuration: config
)
```

### Device-Specific Presets

```swift
// Automatically choose optimal configuration
let config = LlamaUtilities.recommendedConfiguration()

// Or use predefined presets
let lowMemConfig = LlamaConfiguration.lowMemory      // For older devices
let highPerfConfig = LlamaConfiguration.highPerformance  // For newer devices
let simConfig = LlamaConfiguration.simulator        // For simulator testing
```

## Architecture

The package is structured following Swift best practices:

```
LlamaCppAdapter/
├── Sources/
│   └── LlamaCppAdapter/
│       ├── LlamaRunner.swift          # Main inference interface
│       ├── LlamaConfiguration.swift   # Configuration options
│       ├── LlamaTypes.swift          # Token, Response, ModelInfo types
│       ├── LlamaError.swift          # Error types
│       ├── LlamaUtilities.swift      # Helper utilities
│       └── include/
│           └── llama_adapter.h       # C bridging header
├── Tests/
│   └── LlamaCppAdapterTests/
│       └── LlamaCppAdapterTests.swift
├── Examples/
│   └── ExampleUsage.swift            # Usage examples
└── Package.swift
```

### Core Components

#### `LlamaRunner`
The main interface for model inference. Handles model loading, text generation, and resource management.

```swift
public final class LlamaRunner {
    init(modelURL: URL, configuration: LlamaConfiguration) throws
    func loadModel() async throws
    func unloadModel()
    func run(with prompt: String) -> AsyncThrowingStream<LlamaToken, Error>
    func generate(from prompt: String) async throws -> LlamaResponse
    func getModelInfo() -> LlamaModelInfo?
}
```

#### `LlamaConfiguration`
Configures inference parameters with sensible defaults for iOS devices.

```swift
public struct LlamaConfiguration {
    let threads: Int
    let maxTokens: Int
    let temperature: Float
    let topP: Float
    let topK: Int
    let contextSize: Int
    let batchSize: Int
    let useMetalAcceleration: Bool
    let stopTokens: [String]
}
```

#### `LlamaUtilities`
Helper functions for device capabilities and model validation.

```swift
public enum LlamaUtilities {
    static var isMetalAvailable: Bool
    static func recommendedConfiguration() -> LlamaConfiguration
    static func isValidGGUFModel(at url: URL) -> Bool
    static func formatBytes(_ bytes: Int) -> String
}
```

## SwiftUI Integration

```swift
import SwiftUI
import LlamaCppAdapter

struct ContentView: View {
    @State private var prompt = ""
    @State private var response = ""
    @State private var isGenerating = false
    
    private let runner: LlamaRunner
    
    init() {
        runner = try! LlamaRunner(
            modelPath: "/path/to/model.gguf",
            configuration: .simulator
        )
    }
    
    var body: some View {
        VStack {
            TextField("Enter prompt", text: $prompt)
            
            Button("Generate") {
                Task {
                    isGenerating = true
                    response = ""
                    for try await token in runner.run(with: prompt) {
                        response += token.text
                    }
                    isGenerating = false
                }
            }
            .disabled(isGenerating)
            
            Text(response)
        }
        .task {
            try? await runner.loadModel()
        }
    }
}
```

## Model Preparation

LlamaCppAdapter works with GGUF format models. To prepare a model:

1. **Download a model** - Get a pre-quantized GGUF model from Hugging Face
   - Recommended: Q4_0 or Q4_K_M quantization for iOS
   - Suggested size: 1B-7B parameters for mobile devices

2. **Or convert your own model:**
   ```bash
   # Clone llama.cpp
   git clone https://github.com/ggml-org/llama.cpp
   cd llama.cpp
   
   # Convert and quantize
   python convert.py /path/to/model --outtype f16
   ./quantize model.gguf model_q4_0.gguf q4_0
   ```

3. **Add to your iOS project:**
   - Add the `.gguf` file to your Xcode project
   - Ensure it's included in Copy Bundle Resources
   - Reference it in your code:
   ```swift
   let modelURL = Bundle.main.url(forResource: "model_q4_0", withExtension: "gguf")!
   ```

## Testing in iOS Simulator

The library is designed to work in the iOS Simulator:

```swift
#if targetEnvironment(simulator)
let config = LlamaConfiguration.simulator
#else
let config = LlamaConfiguration.highPerformance
#endif

let runner = try LlamaRunner(modelPath: modelPath, configuration: config)
```

**Note:** Simulator runs on CPU only (no Metal acceleration), so expect slower performance compared to physical devices.

## Error Handling

The library provides comprehensive error types:

```swift
do {
    let runner = try LlamaRunner(modelPath: modelPath)
    try await runner.loadModel()
    let response = try await runner.generate(from: prompt)
    
} catch LlamaError.modelNotFound(let path) {
    print("Model not found: \(path)")
    
} catch LlamaError.modelLoadFailed(let reason) {
    print("Load failed: \(reason)")
    
} catch LlamaError.resourceExhausted(let reason) {
    print("Not enough memory: \(reason)")
    // Try .lowMemory configuration
    
} catch {
    print("Error: \(error)")
}
```

## Performance Tips

1. **Use appropriate quantization:**
   - Q4_0 or Q4_K_M for best size/quality balance
   - Q8_0 for better quality with more memory

2. **Optimize configuration:**
   - Use `LlamaConfiguration.lowMemory` for devices with <4GB RAM
   - Enable Metal acceleration on physical devices
   - Adjust `contextSize` based on your needs

3. **Model size guidelines:**
   - iPhone with 4GB RAM: Up to 3B parameters (Q4)
   - iPhone with 6GB RAM: Up to 7B parameters (Q4)
   - iPad Pro: 7B-13B parameters possible

4. **Preload models:**
   - Load models at app launch for faster inference
   - Keep models loaded during active sessions

## Roadmap

This package now integrates with the actual llama.cpp C/C++ library!

- [x] Integration with actual llama.cpp C/C++ library
- [ ] XCFramework distribution for easier integration
- [ ] Model downloading and caching utilities
- [ ] Advanced sampling strategies
- [ ] Batch inference support
- [ ] LoRA adapter support
- [ ] Core ML integration
- [ ] Comprehensive performance benchmarks

## Contributing

Contributions are welcome! This project aims to provide the best Swift interface for llama.cpp on Apple platforms.

## License

This project is a wrapper/adapter for llama.cpp. Please refer to the [llama.cpp license](https://github.com/ggml-org/llama.cpp/blob/master/LICENSE) for the underlying library.

## Acknowledgments

- [llama.cpp](https://github.com/ggml-org/llama.cpp) - The excellent C++ inference library
- Apple Metal team for GPU acceleration APIs
- Swift community for async/await patterns

## Resources

- [llama.cpp Repository](https://github.com/ggml-org/llama.cpp)
- [GGUF Format Specification](https://github.com/ggml-org/ggml/blob/master/docs/gguf.md)
- [Hugging Face Model Hub](https://huggingface.co/models?library=gguf)

## Documentation

- **[QUICKSTART.md](QUICKSTART.md)** - Quick start guide with examples
- **[DEBUGGING.md](DEBUGGING.md)** - Complete guide to debugging in Xcode
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Architecture and design decisions
- **[INTEGRATION.md](INTEGRATION.md)** - Integrating llama.cpp C/C++ library

## Support

For issues and questions:
- Open an issue on GitHub
- Check existing examples in the `Examples/` directory
- Review the test cases in `Tests/` for additional usage patterns
