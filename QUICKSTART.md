# Quick Start Guide

This guide will help you get started with LlamaCppAdapter quickly.

## Installation

### Option 1: Add to Xcode Project

1. Open your Xcode project
2. Go to **File → Add Packages...**
3. Enter: `https://github.com/Sefito/llamaCppAdapter`
4. Click **Add Package**

### Option 2: Add to Package.swift

```swift
dependencies: [
    .package(url: "https://github.com/Sefito/llamaCppAdapter", from: "1.0.0")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["LlamaCppAdapter"]
    )
]
```

## Getting a Model

### Download a Pre-quantized Model

Visit [Hugging Face](https://huggingface.co/models?library=gguf) and search for GGUF models:

**Recommended models for iOS:**
- **TinyLlama-1.1B** (Q4_K_M) - Great for testing, ~700MB
- **Phi-2** (Q4_K_M) - Good quality, ~1.6GB
- **Mistral-7B** (Q4_K_M) - High quality, ~4GB (iPad/newer iPhones)

Example download:
```bash
# Download TinyLlama for testing
curl -L https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf -o model.gguf
```

### Add Model to Your iOS App

1. Drag the `.gguf` file into your Xcode project
2. Make sure "Copy items if needed" is checked
3. Ensure it's added to your app target
4. The model will be in your app bundle

## Basic Usage

### 1. Import the Library

```swift
import LlamaCppAdapter
```

### 2. Get the Model Path

```swift
// From app bundle
guard let modelURL = Bundle.main.url(
    forResource: "tinyllama-1.1b-chat-v1.0.Q4_K_M",
    withExtension: "gguf"
) else {
    fatalError("Model not found in bundle")
}
```

### 3. Create a Runner

```swift
do {
    // Use appropriate config for your device
    #if targetEnvironment(simulator)
    let config = LlamaConfiguration.simulator
    #else
    let config = LlamaUtilities.recommendedConfiguration()
    #endif
    
    let runner = try LlamaRunner(
        modelURL: modelURL,
        configuration: config
    )
    
    // Load the model (do this once)
    try await runner.loadModel()
    
} catch {
    print("Error initializing model: \(error)")
}
```

### 4. Generate Text

```swift
let prompt = "Explain what Swift is in one sentence:"

do {
    let response = try await runner.generate(from: prompt)
    print("Generated: \(response.text)")
    print("Speed: \(response.tokensPerSecond) tokens/sec")
} catch {
    print("Error: \(error)")
}
```

## Complete SwiftUI Example

```swift
import SwiftUI
import LlamaCppAdapter

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ChatView()
        }
    }
}

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var inputText = ""
    
    var body: some View {
        VStack {
            // Output
            ScrollView {
                Text(viewModel.response)
                    .padding()
            }
            
            // Input
            HStack {
                TextField("Ask something...", text: $inputText)
                    .textFieldStyle(.roundedBorder)
                
                Button("Send") {
                    viewModel.generate(from: inputText)
                    inputText = ""
                }
                .disabled(viewModel.isGenerating || inputText.isEmpty)
            }
            .padding()
        }
        .task {
            await viewModel.loadModel()
        }
    }
}

@MainActor
class ChatViewModel: ObservableObject {
    @Published var response = ""
    @Published var isGenerating = false
    
    private var runner: LlamaRunner?
    
    func loadModel() async {
        guard let modelURL = Bundle.main.url(
            forResource: "model",
            withExtension: "gguf"
        ) else {
            response = "Error: Model not found"
            return
        }
        
        do {
            #if targetEnvironment(simulator)
            let config = LlamaConfiguration.simulator
            #else
            let config = LlamaUtilities.recommendedConfiguration()
            #endif
            
            runner = try LlamaRunner(modelURL: modelURL, configuration: config)
            try await runner?.loadModel()
            response = "Model loaded. Ask me anything!"
            
        } catch {
            response = "Error loading model: \(error.localizedDescription)"
        }
    }
    
    func generate(from prompt: String) {
        guard let runner = runner else { return }
        
        isGenerating = true
        response = ""
        
        Task {
            do {
                // Stream tokens in real-time
                for try await token in runner.run(with: prompt) {
                    response += token.text
                }
            } catch {
                response = "Error: \(error.localizedDescription)"
            }
            isGenerating = false
        }
    }
}
```

## Testing in Simulator

The library works in the iOS Simulator:

```swift
#if targetEnvironment(simulator)
// Use simulator-optimized configuration
let config = LlamaConfiguration.simulator
#else
// Use full performance on device
let config = LlamaConfiguration.highPerformance
#endif
```

**Note:** Simulator performance will be slower since Metal acceleration is unavailable.

## Troubleshooting

### "Model not found"
- Ensure the `.gguf` file is added to your Xcode project
- Check it's included in "Copy Bundle Resources" in Build Phases
- Verify the file name matches your code

### "Out of memory" error
- Use a smaller model (1B-3B parameters)
- Try lower quantization (Q4_0 instead of Q8_0)
- Use `LlamaConfiguration.lowMemory` preset

### Slow inference
- On device: Ensure Metal acceleration is enabled
- Use appropriate quantization (Q4_K_M is a good balance)
- Reduce context size if needed

### Build errors
- Ensure you're using Xcode 14+ and Swift 5.9+
- Check minimum deployment target is iOS 14.0+

## Next Steps

- Read the [README](README.md) for complete API documentation
- Check [ARCHITECTURE.md](ARCHITECTURE.md) for design details
- See [INTEGRATION.md](INTEGRATION.md) to connect llama.cpp
- Explore [Examples/ExampleUsage.swift](Examples/ExampleUsage.swift) for more patterns

## Support

- **Issues**: [GitHub Issues](https://github.com/Sefito/llamaCppAdapter/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Sefito/llamaCppAdapter/discussions)

## Credits

Built on top of the excellent [llama.cpp](https://github.com/ggml-org/llama.cpp) project.
