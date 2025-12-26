# Testing Guide for llama.cpp Integration

This guide explains how to test the llama.cpp integration in the LlamaCppAdapter package.

## Prerequisites

### 1. Build Environment
- macOS 12.0+ (Monterey or later)
- Xcode 14.0+
- Swift 5.9+
- Physical iOS device or simulator

### 2. Test Model
You need a GGUF format model file. For testing, we recommend starting with a small model:

**Recommended Test Model:**
- **TinyLlama 1.1B Chat Q4_0** (500-800 MB)
- Download from: https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF
- File: `tinyllama-1.1b-chat-v1.0.Q4_0.gguf`

**Alternative Test Models:**
- Phi-2 (2.7B) Q4_0 (~1.5 GB)
- Mistral-7B Q2_K (~2.5 GB) - if you have more memory

### 3. Add Model to Project
```bash
# Download model
curl -L -o tinyllama.gguf "https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_0.gguf"

# Add to your Xcode project's resources
# Or place in a known location and reference by path
```

## Running Tests

### Option 1: Xcode UI Tests

1. **Open Package in Xcode:**
   ```bash
   cd /path/to/llamaCppAdapter
   open Package.swift
   ```

2. **Select Target:**
   - Choose "LlamaCppAdapter" scheme
   - Select iOS Simulator or connected iOS device

3. **Run Tests:**
   - Press ⌘U to run all tests
   - Or use Test Navigator (⌘6) to run specific tests

### Option 2: Command Line (macOS only)

```bash
# Run all tests on macOS
swift test

# Run on iOS simulator (requires xcodebuild)
xcodebuild test \
  -scheme LlamaCppAdapter \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Option 3: Create a Test App

Create a simple test application:

```swift
// TestApp.swift
import SwiftUI
import LlamaCppAdapter

@main
struct TestApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var status = "Ready"
    @State private var output = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text(status)
                .font(.headline)
            
            Button("Test llama.cpp Integration") {
                testIntegration()
            }
            
            ScrollView {
                Text(output)
                    .font(.system(.body, design: .monospaced))
            }
        }
        .padding()
    }
    
    private func testIntegration() {
        Task {
            await runTest()
        }
    }
    
    private func runTest() async {
        status = "Testing..."
        output = ""
        
        do {
            // Update this path to your model location
            let modelPath = "/path/to/tinyllama.gguf"
            
            log("1. Creating runner...")
            let runner = try LlamaRunner(
                modelPath: modelPath,
                configuration: .simulator
            )
            
            log("2. Loading model...")
            try await runner.loadModel()
            
            log("3. Getting model info...")
            if let info = runner.getModelInfo() {
                log("   Architecture: \(info.architecture ?? "unknown")")
                log("   Context: \(info.contextLength ?? 0)")
                log("   Vocab: \(info.vocabularySize ?? 0)")
            }
            
            log("4. Generating text...")
            let response = try await runner.generate(from: "Hello!")
            log("   Output: \(response.text)")
            log("   Tokens: \(response.tokenCount)")
            log("   Speed: \(String(format: "%.2f", response.tokensPerSecond)) tok/s")
            
            log("5. Testing streaming...")
            var streamedText = ""
            for try await token in runner.run(with: "Hi") {
                streamedText += token.text
            }
            log("   Streamed: \(streamedText)")
            
            log("6. Cleaning up...")
            runner.unloadModel()
            
            status = "✅ All tests passed!"
            log("\n✅ Integration test successful!")
            
        } catch {
            status = "❌ Test failed"
            log("❌ Error: \(error)")
        }
    }
    
    private func log(_ message: String) {
        output += message + "\n"
    }
}
```

## Test Cases

### 1. Basic Initialization Test
```swift
func testInitialization() throws {
    let runner = try LlamaRunner(
        modelPath: "/path/to/model.gguf",
        configuration: .simulator
    )
    // Should not throw
}
```

### 2. Model Loading Test
```swift
func testModelLoading() async throws {
    let runner = try LlamaRunner(
        modelPath: "/path/to/model.gguf",
        configuration: .simulator
    )
    try await runner.loadModel()
    runner.unloadModel()
}
```

### 3. Single Token Generation Test
```swift
func testGeneration() async throws {
    let runner = try LlamaRunner(
        modelPath: "/path/to/model.gguf",
        configuration: .simulator
    )
    try await runner.loadModel()
    
    let response = try await runner.generate(from: "Hi")
    
    XCTAssertFalse(response.text.isEmpty)
    XCTAssertGreaterThan(response.tokenCount, 0)
    
    runner.unloadModel()
}
```

### 4. Streaming Test
```swift
func testStreaming() async throws {
    let runner = try LlamaRunner(
        modelPath: "/path/to/model.gguf",
        configuration: .simulator
    )
    try await runner.loadModel()
    
    var tokenCount = 0
    for try await _ in runner.run(with: "Hello") {
        tokenCount += 1
    }
    
    XCTAssertGreaterThan(tokenCount, 0)
    
    runner.unloadModel()
}
```

### 5. Model Info Test
```swift
func testModelInfo() async throws {
    let runner = try LlamaRunner(
        modelPath: "/path/to/model.gguf",
        configuration: .simulator
    )
    try await runner.loadModel()
    
    let info = runner.getModelInfo()
    XCTAssertNotNil(info)
    XCTAssertNotNil(info?.architecture)
    
    runner.unloadModel()
}
```

### 6. Configuration Test
```swift
func testConfiguration() throws {
    let config = LlamaConfiguration(
        threads: 4,
        maxTokens: 100,
        temperature: 0.7,
        topP: 0.9,
        topK: 40,
        contextSize: 1024,
        batchSize: 256,
        useMetalAcceleration: false
    )
    
    let runner = try LlamaRunner(
        modelPath: "/path/to/model.gguf",
        configuration: config
    )
    
    // Should initialize with custom config
}
```

### 7. Error Handling Test
```swift
func testInvalidModelPath() {
    XCTAssertThrowsError(
        try LlamaRunner(modelPath: "/invalid/path/model.gguf")
    ) { error in
        XCTAssertTrue(error is LlamaError)
    }
}
```

## Performance Testing

### Measure Tokens Per Second
```swift
func testPerformance() async throws {
    let runner = try LlamaRunner(
        modelPath: "/path/to/model.gguf",
        configuration: .highPerformance
    )
    try await runner.loadModel()
    
    let prompt = "Once upon a time"
    let startTime = Date()
    
    let response = try await runner.generate(from: prompt)
    
    let elapsed = Date().timeIntervalSince(startTime)
    let tokensPerSecond = Double(response.tokenCount) / elapsed
    
    print("Performance:")
    print("  Tokens: \(response.tokenCount)")
    print("  Time: \(String(format: "%.2f", elapsed))s")
    print("  Speed: \(String(format: "%.2f", tokensPerSecond)) tok/s")
    
    // Assert minimum performance
    XCTAssertGreaterThan(tokensPerSecond, 1.0, "Should generate at least 1 token per second")
    
    runner.unloadModel()
}
```

### Measure First Token Latency
```swift
func testFirstTokenLatency() async throws {
    let runner = try LlamaRunner(
        modelPath: "/path/to/model.gguf",
        configuration: .highPerformance
    )
    try await runner.loadModel()
    
    let startTime = Date()
    var firstTokenTime: TimeInterval?
    
    for try await token in runner.run(with: "Hi") {
        if firstTokenTime == nil {
            firstTokenTime = Date().timeIntervalSince(startTime)
        }
        break // Only measure first token
    }
    
    if let latency = firstTokenTime {
        print("First token latency: \(String(format: "%.3f", latency))s")
        XCTAssertLessThan(latency, 5.0, "First token should arrive within 5 seconds")
    }
    
    runner.unloadModel()
}
```

## Expected Results

### Simulator (CPU Only)
- **Initialization:** < 1 second
- **Model Loading:** 2-10 seconds (depends on model size)
- **First Token:** 500ms - 3 seconds
- **Generation Speed:** 2-10 tokens/second
- **Memory Usage:** Model size + ~500MB overhead

### iOS Device (with Metal)
- **Initialization:** < 1 second
- **Model Loading:** 1-5 seconds
- **First Token:** 200ms - 1 second
- **Generation Speed:** 10-50 tokens/second (depends on device)
- **Memory Usage:** Model size + ~300MB overhead

### macOS (with Metal)
- **Initialization:** < 1 second
- **Model Loading:** 1-3 seconds
- **First Token:** 100ms - 500ms
- **Generation Speed:** 20-100 tokens/second (depends on CPU/GPU)
- **Memory Usage:** Model size + ~300MB overhead

## Troubleshooting Tests

### Test Fails to Build
```bash
# Clean build
rm -rf .build
swift package clean

# Update dependencies
swift package update
```

### Model Loading Fails
- Check model file exists and is readable
- Verify model is valid GGUF format
- Try smaller model or `.lowMemory` configuration
- Check available device memory

### Tests Time Out
- Increase test timeout in scheme settings
- Use smaller model for testing
- Reduce `maxTokens` in configuration
- Use `.simulator` preset for faster tests

### Metal Not Available in Simulator
This is expected! Simulator doesn't support Metal. Use:
```swift
let config = LlamaConfiguration.simulator // Metal disabled
```

## Continuous Integration

For CI/CD pipelines:

```yaml
# .github/workflows/test.yml
name: Test
on: [push, pull_request]
jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: latest-stable
      
      - name: Run Tests
        run: swift test
```

## Manual Verification Checklist

- [ ] Package builds without errors
- [ ] Model loads successfully
- [ ] Text generation produces output
- [ ] Streaming works token-by-token
- [ ] Model info extraction works
- [ ] Memory is freed on unload
- [ ] Error handling works correctly
- [ ] Configuration presets work
- [ ] Metal acceleration works on device
- [ ] CPU fallback works in simulator

## Reporting Issues

If tests fail, please include:
1. macOS and Xcode versions
2. Device/simulator being tested
3. Model file and size
4. Configuration used
5. Full error message
6. Console logs

Example issue:
```
**Environment:**
- macOS: 14.0
- Xcode: 15.0
- Device: iPhone 15 Simulator
- Model: TinyLlama 1.1B Q4_0

**Configuration:**
LlamaConfiguration.simulator

**Error:**
Model loading failed: Failed to create context

**Logs:**
[Include full console output]
```

## Success Criteria

✅ Integration is successful if:
1. Package builds without errors
2. Model loads and reports correct metadata
3. Text generation produces coherent output
4. Tokens stream in real-time
5. Performance meets expectations for platform
6. Memory is properly managed
7. Error handling works as expected

## Next Steps After Testing

Once tests pass:
1. Integrate into your app
2. Test with your specific models
3. Optimize configuration for your use case
4. Implement your UI/UX
5. Test on multiple devices
6. Profile memory and performance
7. Deploy to TestFlight

Happy testing! 🚀
