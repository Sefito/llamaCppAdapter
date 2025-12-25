# Debugging Guide for Xcode

This guide explains how to debug the LlamaCppAdapter project in Xcode, including setting up breakpoints, debugging Swift code, and troubleshooting common issues.

## Prerequisites

- **Xcode 14.0 or later**
- **macOS 11.0 or later**
- Basic familiarity with Xcode and Swift debugging

## Opening the Project in Xcode

### Method 1: Generate Xcode Project

Swift Package Manager can generate an Xcode project:

```bash
cd /path/to/llamaCppAdapter
swift package generate-xcodeproj
open LlamaCppAdapter.xcodeproj
```

**Note:** Xcode projects generated this way are read-only. Changes should be made to the source files directly.

### Method 2: Open Package Directly (Recommended)

Since Xcode 11, you can open Swift Packages directly:

```bash
cd /path/to/llamaCppAdapter
open Package.swift
```

Or from Xcode: **File → Open** → Select `Package.swift`

### Method 3: Add to iOS/macOS App

For real-world debugging, integrate into an actual app:

1. Create a new iOS/macOS app in Xcode
2. **File → Add Packages...**
3. Choose **Add Local...** and select the `llamaCppAdapter` folder
4. Add `LlamaCppAdapter` to your target's frameworks

## Setting Up for Debugging

### 1. Build Configuration

Set the build configuration for debugging:

1. **Product → Scheme → Edit Scheme** (⌘<)
2. Select **Run** in the left sidebar
3. Under **Info**, set **Build Configuration** to **Debug**
4. Enable **Debug executable**

### 2. Enable Debug Symbols

In `Package.swift`, debug symbols are enabled by default in Debug builds. To verify:

```swift
// Debug symbols are automatically included in debug builds
// No additional configuration needed for Swift Package Manager
```

### 3. Disable Optimizations (Optional)

For easier debugging, you can disable optimizations:

Edit **Build Settings** and set:
- **Swift Compiler - Code Generation → Optimization Level** to **No Optimization [-Onone]**

## Debugging Swift Code

### Setting Breakpoints

#### In Xcode:

1. **Open the source file** (e.g., `LlamaRunner.swift`)
2. **Click in the gutter** (left side of line numbers) to add a breakpoint
3. Breakpoint markers appear as blue indicators

**Keyboard shortcut:** ⌘\ (toggle breakpoint on current line)

#### Conditional Breakpoints:

1. **Right-click a breakpoint** → **Edit Breakpoint**
2. Add a **Condition** (e.g., `prompt.count > 100`)
3. Optionally add **Actions** (log message, run script, etc.)

#### Strategic Breakpoint Locations:

```swift
// LlamaRunner.swift

public init(modelURL: URL, configuration: LlamaConfiguration) throws {
    // ✓ Breakpoint here to debug initialization
    self.modelURL = modelURL
    self.configuration = configuration
    
    guard FileManager.default.fileExists(atPath: modelURL.path) else {
        // ✓ Breakpoint here to catch file not found
        throw LlamaError.modelNotFound(path: modelURL.path)
    }
    
    try validateConfiguration(configuration)
}

public func loadModel() async throws {
    // ✓ Breakpoint here to debug model loading
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
        queue.async { [weak self] in
            // ✓ Breakpoint inside async block
            guard let self = self else {
                continuation.resume(throwing: LlamaError.modelLoadFailed(reason: "Runner deallocated"))
                return
            }
            
            // Add your llama.cpp loading code here
            self.isModelLoaded = true
            continuation.resume()
        }
    }
}

private func generateTokens(...) async throws {
    // ✓ Breakpoint here to debug token generation
    guard !prompt.isEmpty else {
        throw LlamaError.invalidPrompt
    }
    
    // ✓ Breakpoint in token generation loop
    continuation.yield(placeholderToken)
}
```

### LLDB Commands

When stopped at a breakpoint, use the **Debug Console** (⌘⇧Y):

#### Print Variables:
```lldb
(lldb) po modelURL
(lldb) po configuration
(lldb) p configuration.threads
(lldb) expr configuration.maxTokens
```

#### Navigate Execution:
```lldb
(lldb) continue   # or 'c' - Continue execution
(lldb) step       # or 's' - Step into function
(lldb) next       # or 'n' - Step over line
(lldb) finish     # or 'f' - Step out of function
```

#### Inspect Memory:
```lldb
(lldb) frame variable   # Show all variables in current frame
(lldb) bt              # Show backtrace/call stack
(lldb) thread list     # List all threads
```

#### Modify Values at Runtime:
```lldb
(lldb) expr configuration.maxTokens = 100
(lldb) po configuration.maxTokens  # Verify change
```

### View Memory Graph

Debug memory issues and retain cycles:

1. Run the app
2. **Debug → Debug Memory Graph** (or click memory graph icon in debug bar)
3. Look for purple warning icons indicating leaks
4. Inspect object relationships in the graph

## Debugging Async Code

### Async/Await Debugging:

The package uses Swift concurrency. Key debugging points:

```swift
// Set breakpoints in async contexts
Task {
    do {
        let runner = try LlamaRunner(modelPath: path)
        try await runner.loadModel()  // ← Breakpoint here
        
        for try await token in runner.run(with: prompt) {  // ← And here
            print(token.text)
        }
    } catch {
        print(error)  // ← Breakpoint to catch errors
    }
}
```

**View Task Inspector:**
- **Debug → Debug Workflow → Show Task Inspector**
- Shows all active tasks and their state

### Debugging Continuation Issues:

```swift
// Common issue: forgetting to resume continuation
try await withCheckedThrowingContinuation { continuation in
    // ⚠️ Breakpoint here - ensure continuation.resume() is called
    queue.async {
        // ... work ...
        continuation.resume()  // ← Must be called exactly once
    }
}
```

**Warning:** Not resuming a continuation will hang forever.

## Debugging Tests

### Run Tests in Xcode

1. **Product → Test** (⌘U) - Run all tests
2. **Click diamond icon** next to test function - Run single test
3. **Test Navigator** (⌘5) - View all tests

### Debug Test Failures:

1. Set breakpoints in test code
2. **Right-click test** → **Debug "testName"**
3. Execution will stop at breakpoints

Example test debugging:

```swift
func testRunnerInitialization() {
    let tempURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("test_model.gguf")
    _ = FileManager.default.createFile(atPath: tempURL.path, contents: Data())
    defer { try? FileManager.default.removeItem(at: tempURL) }
    
    // ✓ Breakpoint here to verify file creation
    XCTAssertTrue(FileManager.default.fileExists(atPath: tempURL.path))
    
    do {
        let runner = try LlamaRunner(modelURL: tempURL)
        // ✓ Breakpoint here to inspect runner
        XCTAssertNotNil(runner)
    } catch {
        // ✓ Breakpoint here to debug unexpected errors
        XCTFail("Unexpected error: \(error)")
    }
}
```

### View Test Logs:

- **Report Navigator** (⌘9) → Select test run
- Expand test to see logs and failures
- Click failure to jump to code

## Debugging iOS Simulator

### Simulator-Specific Configuration:

```swift
#if targetEnvironment(simulator)
let config = LlamaConfiguration.simulator
print("Running in simulator - Metal disabled")
#else
let config = LlamaConfiguration.highPerformance
print("Running on device - Metal enabled")
#endif
```

**Debug Metal Availability:**

```swift
// Add breakpoint here to verify Metal state
if LlamaUtilities.isMetalAvailable {
    print("Metal is available")
    // On simulator, this should be false
} else {
    print("Metal not available - using CPU")
}
```

### Simulator Debugging Tips:

1. **Enable Debug Console:** Debug → Activate Console (⌘⇧C)
2. **Slower performance is expected** - Simulator uses CPU only
3. **Test memory-constrained scenarios** by using smaller models
4. **Check device type:** Debug → Simulate Device → Choose different iPhone/iPad

### Debug GPU/Metal Code (Device Only):

1. **Product → Scheme → Edit Scheme**
2. **Run → Diagnostics** tab
3. Enable **Metal API Validation**
4. Enable **GPU Frame Capture**
5. Run on physical device
6. **Debug → Capture GPU Frame** (when inference is running)

## Common Debugging Scenarios

### 1. Model Not Loading

**Symptoms:** `modelNotFound` or `modelLoadFailed` errors

**Debug steps:**
```swift
// Add breakpoints and logging:
public init(modelURL: URL, configuration: LlamaConfiguration) throws {
    print("🔍 Model URL: \(modelURL)")
    print("🔍 File exists: \(FileManager.default.fileExists(atPath: modelURL.path))")
    
    guard FileManager.default.fileExists(atPath: modelURL.path) else {
        print("❌ File not found at: \(modelURL.path)")
        throw LlamaError.modelNotFound(path: modelURL.path)
    }
    
    // Check file size
    if let attrs = try? FileManager.default.attributesOfItem(atPath: modelURL.path),
       let size = attrs[.size] as? Int {
        print("📊 Model size: \(LlamaUtilities.formatBytes(size))")
    }
    
    // Validate GGUF format
    print("🔍 Valid GGUF: \(LlamaUtilities.isValidGGUFModel(at: modelURL))")
}
```

### 2. Memory Issues

**Symptoms:** App crashes, `resourceExhausted` errors

**Debug steps:**
1. **Debug → Memory Report** - Check memory usage
2. Enable **Address Sanitizer:**
   - **Product → Scheme → Edit Scheme**
   - **Run → Diagnostics** → Enable **Address Sanitizer**
3. Use smaller model or `.lowMemory` configuration

```swift
// Add memory monitoring:
func loadModel() async throws {
    let before = ProcessInfo.processInfo.physicalMemory
    print("💾 Memory before load: \(LlamaUtilities.formatBytes(Int(before)))")
    
    try await withCheckedThrowingContinuation { continuation in
        // ... loading code ...
    }
    
    print("💾 Memory after load: \(ProcessInfo.processInfo.physicalMemory)")
}
```

### 3. Async/Await Hangs

**Symptoms:** Code stops executing, no errors

**Debug steps:**
1. **Pause execution** (⌃⌘Y or pause button)
2. Check **Thread List** to see where code is stuck
3. Verify all continuations are resumed

```swift
// Add timeout for debugging:
Task {
    do {
        let timeout = Task {
            try await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
            print("⚠️ Timeout - loadModel took too long")
        }
        
        try await runner.loadModel()
        timeout.cancel()
        
    } catch {
        print("❌ Error: \(error)")
    }
}
```

### 4. Token Generation Not Working

**Debug token stream:**

```swift
for try await token in runner.run(with: prompt) {
    print("🔤 Token: '\(token.text)' (id: \(token.id))")
    
    if let prob = token.probability {
        print("   Probability: \(prob)")
    }
}
```

## Performance Profiling

### Using Instruments:

1. **Product → Profile** (⌘I)
2. Choose template:
   - **Time Profiler** - CPU usage
   - **Allocations** - Memory allocations
   - **Leaks** - Memory leaks
   - **System Trace** - System calls
3. Run the app and exercise inference
4. Analyze the timeline and statistics

### Measure Inference Speed:

```swift
let startTime = Date()
let response = try await runner.generate(from: prompt)
let elapsed = Date().timeIntervalSince(startTime)

print("⏱ Generated \(response.tokenCount) tokens in \(elapsed)s")
print("🚀 Speed: \(response.tokensPerSecond) tokens/sec")
```

## Advanced Debugging

### Symbolic Breakpoints:

Set breakpoints on all errors:
1. **Debug Navigator** (⌘7) → **Breakpoint Navigator**
2. Click **+** → **Symbolic Breakpoint**
3. Set **Symbol** to `Swift.Error` or `NSException`

### Exception Breakpoint:

Catch all thrown exceptions:
1. **Breakpoint Navigator** → **+** → **Exception Breakpoint**
2. Set to catch **All Exceptions**

### Debug Print Statements:

Add conditional logging:

```swift
#if DEBUG
private let debugLogging = true
#else
private let debugLogging = false
#endif

private func debugLog(_ message: String) {
    #if DEBUG
    print("[LlamaCppAdapter] \(message)")
    #endif
}

// Usage:
debugLog("Model loaded successfully")
debugLog("Generating tokens for prompt: \(prompt)")
```

### View Debug Hierarchy:

When debugging SwiftUI views:
1. Run the app
2. **Debug → View Debugging → Capture View Hierarchy**
3. Inspect the 3D view of your UI

## Troubleshooting

### "No Such Module" Error

**Solution:**
1. Clean build folder: **Product → Clean Build Folder** (⌘⇧K)
2. Delete derived data: `~/Library/Developer/Xcode/DerivedData`
3. Rebuild: **Product → Build** (⌘B)

### Breakpoints Not Hitting

**Solutions:**
1. Ensure **Debug** build configuration is selected
2. Check breakpoint is enabled (blue, not gray)
3. Code might be optimized out - disable optimizations
4. Clean and rebuild

### Can't Inspect Variables (Shows "error: ...")

**Solutions:**
1. Ensure debug symbols are included
2. Try `po` instead of `p` for objects
3. Some optimizations prevent inspection

### Simulator vs Device Differences

**Best practices:**
- Test on both simulator AND physical device
- Use `#if targetEnvironment(simulator)` for simulator-specific code
- Remember Metal is unavailable in simulator
- Performance will be much slower in simulator

## Quick Reference

| Action | Shortcut |
|--------|----------|
| Build | ⌘B |
| Run | ⌘R |
| Test | ⌘U |
| Stop | ⌘. |
| Clean | ⌘⇧K |
| Toggle Breakpoint | ⌘\ |
| Step Over | F6 |
| Step Into | F7 |
| Step Out | F8 |
| Continue | ⌃⌘Y |
| Show/Hide Console | ⌘⇧Y |
| Show Debug Area | ⌘⇧C |

## Additional Resources

- [Xcode Debugging Documentation](https://developer.apple.com/documentation/xcode/debugging)
- [LLDB Quick Start](https://developer.apple.com/library/archive/documentation/IDEs/Conceptual/gdb_to_lldb_transition_guide/document/lldb-basics.html)
- [Swift Concurrency Debugging](https://developer.apple.com/videos/play/wwdc2021/10226/)
- [Instruments Tutorial](https://developer.apple.com/videos/play/wwdc2023/10248/)

## Getting Help

If you encounter issues not covered in this guide:

1. Check the [main README](README.md) for general usage
2. Review [ARCHITECTURE.md](ARCHITECTURE.md) for design details
3. See [INTEGRATION.md](INTEGRATION.md) for integration steps
4. Open an issue on [GitHub](https://github.com/Sefito/llamaCppAdapter/issues)
