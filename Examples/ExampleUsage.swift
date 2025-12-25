import Foundation
import LlamaCppAdapter

/// Example usage of LlamaCppAdapter
/// 
/// This file demonstrates how to use the LlamaCppAdapter library
/// to run Llama models on iOS devices and simulators

@available(iOS 14.0, macOS 11.0, *)
class LlamaExample {
    
    // MARK: - Basic Usage
    
    /// Example 1: Simple text generation
    static func basicExample() async throws {
        // Initialize the runner with a model file
        let modelPath = "/path/to/your/model.gguf"
        let runner = try LlamaRunner(modelPath: modelPath)
        
        // Load the model
        try await runner.loadModel()
        
        // Generate text
        let prompt = "Once upon a time"
        let response = try await runner.generate(from: prompt)
        
        print("Generated text: \(response.text)")
        print("Tokens: \(response.tokenCount)")
        print("Speed: \(String(format: "%.2f", response.tokensPerSecond)) tokens/sec")
        
        // Clean up
        runner.unloadModel()
    }
    
    // MARK: - Streaming Example
    
    /// Example 2: Stream tokens as they're generated
    static func streamingExample() async throws {
        let modelPath = "/path/to/your/model.gguf"
        let runner = try LlamaRunner(modelPath: modelPath)
        
        try await runner.loadModel()
        
        let prompt = "Explain quantum computing in simple terms:"
        
        print("Streaming response:")
        for try await token in runner.run(with: prompt) {
            print(token.text, terminator: "")
            // Update UI in real-time here
        }
        print("\n")
        
        runner.unloadModel()
    }
    
    // MARK: - Custom Configuration
    
    /// Example 3: Using custom configuration
    static func customConfigExample() async throws {
        // Create a custom configuration
        let config = LlamaConfiguration(
            threads: 4,
            maxTokens: 256,
            temperature: 0.8,
            topP: 0.95,
            topK: 40,
            contextSize: 2048,
            batchSize: 512,
            useMetalAcceleration: true,
            stopTokens: ["\n\n", "User:", "Assistant:"]
        )
        
        let modelPath = "/path/to/your/model.gguf"
        let runner = try LlamaRunner(modelPath: modelPath, configuration: config)
        
        try await runner.loadModel()
        
        let response = try await runner.generate(from: "What is Swift?")
        print("Response: \(response.text)")
        
        runner.unloadModel()
    }
    
    // MARK: - Device-Specific Configuration
    
    /// Example 4: Using device-specific presets
    static func deviceSpecificExample() async throws {
        // Get recommended configuration for current device
        let config = LlamaUtilities.recommendedConfiguration()
        
        let modelPath = "/path/to/your/model.gguf"
        let runner = try LlamaRunner(modelPath: modelPath, configuration: config)
        
        try await runner.loadModel()
        
        // Check Metal availability
        if LlamaUtilities.isMetalAvailable {
            print("Using Metal acceleration")
        } else {
            print("Metal not available, using CPU")
        }
        
        let response = try await runner.generate(from: "Hello, world!")
        print("Response: \(response.text)")
        
        runner.unloadModel()
    }
    
    // MARK: - Model Validation
    
    /// Example 5: Validate model before loading
    static func validateModelExample() throws {
        let modelURL = URL(fileURLWithPath: "/path/to/your/model.gguf")
        
        // Check if model file is valid
        guard LlamaUtilities.isValidGGUFModel(at: modelURL) else {
            throw LlamaError.modelLoadFailed(reason: "Invalid GGUF model file")
        }
        
        // Get model size
        if let size = LlamaUtilities.getModelSize(at: modelURL) {
            print("Model size: \(LlamaUtilities.formatBytes(size))")
        }
        
        print("Model validation passed!")
    }
    
    // MARK: - Error Handling
    
    /// Example 6: Comprehensive error handling
    static func errorHandlingExample() async {
        let modelPath = "/path/to/your/model.gguf"
        
        do {
            let runner = try LlamaRunner(modelPath: modelPath)
            try await runner.loadModel()
            
            let response = try await runner.generate(from: "Tell me a story")
            print(response.text)
            
            runner.unloadModel()
            
        } catch LlamaError.modelNotFound(let path) {
            print("Model not found at: \(path)")
            print("Please download a GGUF model file first")
            
        } catch LlamaError.modelLoadFailed(let reason) {
            print("Failed to load model: \(reason)")
            print("Try using a smaller model or different quantization")
            
        } catch LlamaError.resourceExhausted(let reason) {
            print("Not enough resources: \(reason)")
            print("Try using .lowMemory configuration preset")
            
        } catch {
            print("Unexpected error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Chatbot Example
    
    /// Example 7: Simple chatbot with conversation history
    static func chatbotExample() async throws {
        let modelPath = "/path/to/your/model.gguf"
        let runner = try LlamaRunner(
            modelPath: modelPath,
            configuration: .highPerformance
        )
        
        try await runner.loadModel()
        
        // Build conversation history
        var conversation = """
        You are a helpful assistant.
        
        User: What is the capital of France?
        Assistant: The capital of France is Paris.
        
        User: What is its population?
        Assistant: 
        """
        
        let response = try await runner.generate(from: conversation)
        print("Assistant: \(response.text)")
        
        runner.unloadModel()
    }
}

// MARK: - SwiftUI Integration Example

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 14.0, macOS 11.0, *)
struct LlamaSwiftUIExample: View {
    @State private var prompt: String = ""
    @State private var response: String = ""
    @State private var isGenerating: Bool = false
    
    private let runner: LlamaRunner
    
    init() {
        // Initialize with your model path
        let modelPath = "/path/to/your/model.gguf"
        self.runner = try! LlamaRunner(
            modelPath: modelPath,
            configuration: .simulator
        )
    }
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Enter your prompt", text: $prompt)
                .textFieldStyle(.roundedBorder)
                .padding()
            
            Button("Generate") {
                generateResponse()
            }
            .disabled(isGenerating || prompt.isEmpty)
            
            if isGenerating {
                ProgressView("Generating...")
            }
            
            ScrollView {
                Text(response)
                    .padding()
            }
        }
        .padding()
        .task {
            // Load model when view appears
            try? await runner.loadModel()
        }
    }
    
    private func generateResponse() {
        isGenerating = true
        response = ""
        
        Task {
            do {
                for try await token in runner.run(with: prompt) {
                    await MainActor.run {
                        response += token.text
                    }
                }
            } catch {
                await MainActor.run {
                    response = "Error: \(error.localizedDescription)"
                }
            }
            
            await MainActor.run {
                isGenerating = false
            }
        }
    }
}
#endif
