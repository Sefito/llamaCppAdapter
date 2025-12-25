# Architecture and Design Decisions

This document explains the architecture and design decisions behind LlamaCppAdapter.

## Design Principles

### 1. Swift-Native Interface
The library exposes a completely Swift-native API, hiding all C/C++ implementation details from users.

**Rationale:**
- Better developer experience with Swift's type system
- Easier to use for iOS developers
- Natural integration with SwiftUI and modern Swift patterns
- Compile-time safety and autocomplete support

### 2. Async/Await and Concurrency
Uses Swift's structured concurrency (`async/await`, `AsyncStream`) instead of callbacks or delegates.

**Benefits:**
- Cleaner, more readable code
- Better error handling
- Natural cancellation support
- Matches modern Swift conventions

### 3. Configuration over Convention
Provides sensible defaults while allowing full customization.

**Design:**
```swift
// Use defaults
let runner = try LlamaRunner(modelPath: path)

// Or customize everything
let config = LlamaConfiguration(
    threads: 8,
    maxTokens: 1024,
    temperature: 0.9
)
let runner = try LlamaRunner(modelPath: path, configuration: config)
```

### 4. Device-Aware Presets
Automatically adapts to device capabilities with `.lowMemory`, `.highPerformance`, and `.simulator` presets.

**Rationale:**
- Simplifies development for different device tiers
- Prevents out-of-memory errors
- Optimizes performance per device
- Simulator-specific configuration for testing

## Architecture Layers

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
│  - Wrapper functions                 │
│  - Type conversions                  │
└─────────────┬───────────────────────┘
              │
┌─────────────▼───────────────────────┐
│     llama.cpp Layer                  │
│  - Model loading/inference           │
│  - Metal acceleration                │
│  - Tokenization                      │
└──────────────────────────────────────┘
```

## Key Components

### LlamaRunner

The main interface following the "Runner" pattern common in ML frameworks.

**Responsibilities:**
- Model lifecycle management (load/unload)
- Inference execution
- Resource management
- Thread safety

**Thread Safety:**
- Uses a serial dispatch queue for synchronization
- Marked as `@unchecked Sendable` with manual synchronization
- All mutable state accessed through the queue

### LlamaConfiguration

Immutable configuration struct following the builder pattern.

**Benefits:**
- Thread-safe by default (struct, no mutation)
- Easy to create variants
- Clear documentation of all options
- Type-safe parameter validation

### AsyncThrowingStream for Streaming

Uses `AsyncThrowingStream<LlamaToken, Error>` for real-time token generation.

**Why not Combine?**
- Async/await is the future of Swift concurrency
- Better integration with Swift 5.5+ code
- Simpler error handling
- Lower overhead

**Example:**
```swift
for try await token in runner.run(with: prompt) {
    updateUI(with: token.text)
}
```

### Error Handling

Comprehensive error types with recovery suggestions.

**Design:**
```swift
enum LlamaError: LocalizedError {
    case modelNotFound(path: String)
    case modelLoadFailed(reason: String)
    // ... more cases
    
    var errorDescription: String? { /* ... */ }
    var recoverySuggestion: String? { /* ... */ }
}
```

**Benefits:**
- Clear error messages for users
- Actionable recovery suggestions
- Type-safe error handling
- Localization support

## Memory Management

### Model Loading Strategy

**Approach:** Explicit load/unload with automatic cleanup on deinit.

```swift
// Explicit loading
try await runner.loadModel()

// Use model...

// Explicit unload (or automatic on deinit)
runner.unloadModel()
```

**Rationale:**
- Gives control over memory usage
- Prevents accidental memory spikes
- Clear lifecycle boundaries
- Fail-fast on load errors

### Resource Cleanup

- `deinit` calls `unloadModel()` automatically
- Uses RAII pattern familiar to iOS developers
- No manual memory management needed by users

## Metal Acceleration

### Automatic Detection

```swift
public static var isMetalAvailable: Bool {
    MTLCreateSystemDefaultDevice() != nil
}
```

### Configuration

Metal is:
- Enabled by default on physical devices
- Disabled by default in simulator
- Configurable via `LlamaConfiguration.useMetalAcceleration`

### Fallback Strategy

If Metal initialization fails, the library falls back to CPU with Accelerate framework.

## Testing Strategy

### Unit Tests
- Test all configuration presets
- Validate error types and messages
- Test utility functions
- Mock-friendly architecture

### Simulator Support
- Special configuration preset
- Disabled Metal acceleration
- Reduced resource requirements
- Allows testing without physical device

### Example Code
- Comprehensive examples in `Examples/`
- SwiftUI integration example
- Error handling patterns
- Various use cases

## Performance Considerations

### Thread Pool
- Uses `ProcessInfo.processorCount` by default
- Configurable for specific needs
- Optimized for Apple Silicon

### Batch Processing
- Configurable batch size for prompt processing
- Trade-off between memory and speed
- Default: 512 tokens

### Context Window
- Configurable context size
- Presets optimized for device memory
- Validation prevents oversized contexts

## Future Extensibility

### Pluggable Backends
The architecture allows for future backend additions:
- Core ML integration
- ONNX Runtime support
- Custom accelerators

### Model Caching
Easy to add model caching layer:
```swift
class ModelCache {
    func get(for url: URL) -> CachedModel?
    func set(_ model: CachedModel, for url: URL)
}
```

### LoRA Adapters
Interface designed to accommodate LoRA in the future:
```swift
struct LlamaConfiguration {
    // Future:
    let loraAdapters: [URL]?
}
```

## Best Practices Followed

1. **Swift API Design Guidelines**
   - Clear, concise naming
   - Proper use of labels
   - Value types where appropriate

2. **iOS Conventions**
   - async/await for async work
   - Proper error handling
   - Resource management patterns

3. **Performance**
   - Metal acceleration where available
   - Optimized defaults
   - Configurable for different scenarios

4. **Documentation**
   - Comprehensive README
   - Inline code documentation
   - Usage examples
   - Integration guide

5. **Testing**
   - Unit tests for all public APIs
   - Simulator support for CI/CD
   - Example code as living documentation

## Comparison to Alternatives

### vs. Direct C++ Integration
**Advantages:**
- ✅ Clean Swift API
- ✅ Better error handling
- ✅ Type safety
- ✅ Easier to use

**Trade-offs:**
- ⚠️ Small performance overhead (minimal)
- ⚠️ Additional abstraction layer

### vs. REST API Wrapper
**Advantages:**
- ✅ True on-device inference
- ✅ No network latency
- ✅ Privacy (no data leaves device)
- ✅ Works offline

**Trade-offs:**
- ⚠️ Larger app size
- ⚠️ Device memory requirements

## Conclusion

This architecture balances:
- **Ease of Use**: Simple, Swift-native API
- **Performance**: Direct C++ integration, Metal acceleration
- **Safety**: Type-safe, error handling
- **Flexibility**: Configurable for various use cases
- **Maintainability**: Clear separation of concerns

The design allows iOS developers to integrate local LLM inference without needing to understand C++ or llama.cpp internals, while still providing full control when needed.
