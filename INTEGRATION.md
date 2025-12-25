# Integration Guide

This guide explains the llama.cpp C/C++ library integration with this Swift package.

## Current Status

This package now includes a **complete integration** with the actual llama.cpp C/C++ library! The integration includes:

- ✅ llama.cpp as a git submodule (automatically managed)
- ✅ Complete C/C++ build configuration in Package.swift
- ✅ Metal acceleration support for GPU inference
- ✅ Full Swift API implementation calling llama.cpp C functions
- ✅ Model loading and context management
- ✅ Token generation with streaming support
- ✅ Sampling strategies (top-k, top-p, temperature)
- ✅ Model metadata extraction

## Architecture

The integration follows a clean layered architecture:

```
┌─────────────────────────────────────┐
│     Swift Application Layer         │
│   (SwiftUI, UIKit, User Code)       │
└─────────────┬───────────────────────┘
              │
┌─────────────▼───────────────────────┐
│     Swift API Layer                  │
│  - LlamaRunner (main interface)      │
│  - LlamaConfiguration                │
│  - LlamaTypes (Token, Response)      │
│  - LlamaError (error handling)       │
│  - LlamaUtilities (helpers)          │
└─────────────┬───────────────────────┘
              │
┌─────────────▼───────────────────────┐
│     C Bridge Layer                   │
│  - llama_adapter.h                   │
│  - Direct calls to llama.cpp API     │
└─────────────┬───────────────────────┘
              │
┌─────────────▼───────────────────────┐
│     llama.cpp C/C++ Library          │
│  - Model loading (llama_model)       │
│  - Context management                │
│  - Tokenization                      │
│  - Token generation                  │
│  - Sampling strategies               │
│  - Metal acceleration                │
└──────────────────────────────────────┘
```

## Key Implementation Details

### Model Loading

The `loadModel()` function in `LlamaRunner.swift` performs the following:

1. **Initializes model parameters** - Configures GPU layers, memory mapping
2. **Loads the model** - Calls `llama_model_load_from_file()`
3. **Creates context** - Calls `llama_new_context_with_model()`
4. **Initializes sampler** - Sets up the sampling chain with top-k, top-p, and temperature

### Token Generation

The `generateTokens()` function implements the full inference loop:

1. **Tokenizes prompt** - Converts text to tokens using `llama_tokenize()`
2. **Processes prompt** - Uses batch processing with `llama_batch` and `llama_decode()`
3. **Generates tokens** - Samples new tokens using `llama_sampler_sample()`
4. **Converts to text** - Uses `llama_token_to_piece()` to get token text
5. **Streams results** - Yields tokens through AsyncThrowingStream
6. **Handles termination** - Stops on EOS tokens or max token limit

### Memory Management

- **RAII Pattern** - Model, context, and sampler are freed in `deinit`
- **Thread Safety** - All operations are serialized through a dispatch queue
- **Backend Initialization** - `llama_backend_init()` is called once globally

### Metal Acceleration

Metal GPU acceleration is configured through:
- `n_gpu_layers` parameter (999 = all layers on GPU)
- Metal framework linking in Package.swift
- Metal shader resource (ggml-metal.metal)
- Automatic fallback to CPU if Metal is unavailable

## Building the Project

### iOS/macOS (Xcode)

The project is designed for iOS and macOS platforms:

```bash
# Open in Xcode
open Package.swift

# Or build from command line (on macOS)
swift build --arch arm64 -Xswiftc "-sdk" -Xswiftc "$(xcrun --show-sdk-path --sdk iphoneos)"
```

### Note on Linux

The package includes platform-specific code (Metal, Accelerate) and cannot be built on Linux. Build on macOS or use Xcode Cloud for CI/CD.

## Usage Example

```swift
import LlamaCppAdapter

// Initialize runner
let runner = try LlamaRunner(
    modelPath: "/path/to/model.gguf",
    configuration: .highPerformance
)

// Load model
try await runner.loadModel()

// Stream tokens
for try await token in runner.run(with: "Once upon a time") {
    print(token.text, terminator: "")
}

// Or get complete response
let response = try await runner.generate(from: "Hello, world!")
print(response.text)
print("Speed: \(response.tokensPerSecond) tokens/sec")

// Get model info
if let info = runner.getModelInfo() {
    print("Model: \(info.architecture ?? "unknown")")
    print("Params: \(info.parameterCount ?? 0)")
}

// Clean up (automatic on deinit)
runner.unloadModel()
```

## Configuration Options

The `LlamaConfiguration` struct provides extensive customization:

- `threads` - Number of CPU threads for inference
- `maxTokens` - Maximum tokens to generate
- `temperature` - Sampling temperature (0.0-2.0)
- `topP` - Nucleus sampling parameter
- `topK` - Top-K sampling parameter
- `contextSize` - Size of context window
- `batchSize` - Batch size for prompt processing
- `useMetalAcceleration` - Enable/disable Metal GPU
- `stopTokens` - Custom stop sequences

### Presets

Three presets are available:
- `.simulator` - Optimized for iOS Simulator (no Metal, smaller context)
- `.lowMemory` - For devices with limited RAM
- `.highPerformance` - For devices with ample resources

## llama.cpp Update Process

The llama.cpp submodule can be updated to get the latest features:

```bash
cd third-party/llama.cpp
git pull origin master
cd ../..
git add third-party/llama.cpp
git commit -m "Update llama.cpp to latest version"
```

## Troubleshooting

### Metal Initialization Fails
- Check that Metal is available on the device
- Try disabling Metal: `configuration.useMetalAcceleration = false`
- Verify Metal shader resource is included in bundle

### Model Load Fails
- Verify the model file exists and is a valid GGUF file
- Check available memory (use `.lowMemory` preset if needed)
- Ensure model is compatible with current llama.cpp version

### Slow Inference
- Enable Metal acceleration on physical devices
- Increase thread count: `configuration.threads = ProcessInfo.processInfo.processorCount`
- Use smaller quantization (Q4_0 instead of Q8_0)
- Reduce context size if not needed

## Advanced Features

### Custom Sampling

While the current implementation uses a standard sampling chain, the underlying llama.cpp API supports:
- Custom sampling strategies
- Grammar-guided generation
- Classifier-free guidance
- Custom penalties

These can be added by extending the sampler configuration in `loadModel()`.

### Batch Processing

The implementation uses batching for prompt processing but could be extended to:
- Process multiple prompts in parallel
- Implement speculative decoding
- Enable draft model support

## Testing

To test the integration:

1. Get a small GGUF model (e.g., TinyLlama 1.1B Q4_0)
2. Add it to your test bundle
3. Run the example code
4. Verify token generation and speed

For unit tests, see `Tests/LlamaCppAdapterTests/`.

## Performance Considerations

- **First Token Latency** - Prompt processing time depends on prompt length
- **Token Generation Speed** - Typically 5-20 tokens/sec on iPhone, 20-60 on iPad
- **Memory Usage** - Roughly: model_size + context_size × 0.5MB
- **Metal Acceleration** - 2-5× speedup on supported devices

## References

- [llama.cpp Repository](https://github.com/ggml-org/llama.cpp)
- [GGUF Format Specification](https://github.com/ggml-org/ggml/blob/master/docs/gguf.md)
- [Apple Metal Programming Guide](https://developer.apple.com/metal/)

## Next Steps

With the core integration complete, possible enhancements include:

1. **Model caching** - Cache loaded models for faster startup
2. **Model quantization** - Perform on-device quantization
3. **LoRA support** - Add adapter merging
4. **Streaming improvements** - Add backpressure handling
5. **Benchmark suite** - Comprehensive performance testing

The integration is production-ready for iOS/macOS applications requiring local LLM inference!
