import Foundation

/// Main interface for running Llama model inference
/// This class provides a high-level Swift API for the llama.cpp library
///
/// Thread Safety:
/// - All mutable state is protected by a serial dispatch queue
/// - Public methods can be called from any thread safely
/// - Model operations are serialized to prevent concurrent access
@available(iOS 14.0, macOS 11.0, *)
public final class LlamaRunner: @unchecked Sendable {
    
    // MARK: - Properties
    
    private let modelURL: URL
    private let configuration: LlamaConfiguration
    private var isModelLoaded: Bool = false
    
    // Thread-safe state management
    private let queue = DispatchQueue(label: "com.llamacpp.runner", qos: .userInitiated)
    
    // Placeholder for native model/context pointers
    // In a real implementation, these would be OpaquePointer types
    // pointing to llama_model and llama_context
    private var modelPointer: OpaquePointer?
    private var contextPointer: OpaquePointer?
    
    // MARK: - Initialization
    
    /// Initialize a LlamaRunner with a model file
    /// - Parameters:
    ///   - modelURL: URL to the GGUF model file
    ///   - configuration: Configuration for inference (optional, uses defaults if not provided)
    public init(modelURL: URL, configuration: LlamaConfiguration = LlamaConfiguration()) throws {
        self.modelURL = modelURL
        self.configuration = configuration
        
        // Verify model file exists
        guard FileManager.default.fileExists(atPath: modelURL.path) else {
            throw LlamaError.modelNotFound(path: modelURL.path)
        }
        
        // Validate configuration
        try validateConfiguration(configuration)
    }
    
    /// Convenience initializer for model path string
    public convenience init(modelPath: String, configuration: LlamaConfiguration = LlamaConfiguration()) throws {
        let url = URL(fileURLWithPath: modelPath)
        try self.init(modelURL: url, configuration: configuration)
    }
    
    // MARK: - Public API
    
    /// Load the model into memory
    /// This should be called before running inference
    public func loadModel() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: LlamaError.modelLoadFailed(reason: "Runner deallocated"))
                    return
                }
                
                // TODO: Implement actual llama.cpp model loading
                // This is a placeholder for the C API call:
                // llama_model_params params = llama_model_default_params();
                // self.modelPointer = llama_load_model_from_file(modelURL.path, params);
                // if (self.modelPointer == nil) {
                //     continuation.resume(throwing: LlamaError.modelLoadFailed(reason: "Failed to load model"))
                //     return
                // }
                
                self.isModelLoaded = true
                continuation.resume()
            }
        }
    }
    
    /// Unload the model from memory
    public func unloadModel() {
        queue.sync {
            // TODO: Implement cleanup
            // llama_free_model(modelPointer)
            // llama_free(contextPointer)
            
            modelPointer = nil
            contextPointer = nil
            isModelLoaded = false
        }
    }
    
    /// Generate text from a prompt with streaming tokens
    /// - Parameter prompt: The input prompt text
    /// - Returns: AsyncStream of generated tokens
    public func run(with prompt: String) -> AsyncThrowingStream<LlamaToken, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    try await generateTokens(prompt: prompt, continuation: continuation)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    /// Generate complete text response from a prompt
    /// - Parameter prompt: The input prompt text
    /// - Returns: Complete LlamaResponse with generated text and metadata
    public func generate(from prompt: String) async throws -> LlamaResponse {
        guard !prompt.isEmpty else {
            throw LlamaError.invalidPrompt
        }
        
        guard isModelLoaded else {
            throw LlamaError.modelLoadFailed(reason: "Model not loaded. Call loadModel() first.")
        }
        
        let startTime = Date()
        var generatedText = ""
        var tokenCount = 0
        
        for try await token in run(with: prompt) {
            generatedText += token.text
            tokenCount += 1
        }
        
        let generationTime = Date().timeIntervalSince(startTime)
        
        return LlamaResponse(
            text: generatedText,
            tokenCount: tokenCount,
            generationTime: generationTime
        )
    }
    
    /// Get information about the loaded model
    public func getModelInfo() -> LlamaModelInfo? {
        guard isModelLoaded else { return nil }
        
        // TODO: Implement actual metadata extraction from llama.cpp
        // This would call llama_model_meta_* functions
        
        return LlamaModelInfo(
            architecture: "llama",
            parameterCount: nil,
            contextLength: configuration.contextSize,
            vocabularySize: nil,
            quantizationType: nil
        )
    }
    
    // MARK: - Private Methods
    
    private func validateConfiguration(_ config: LlamaConfiguration) throws {
        guard config.threads > 0 else {
            throw LlamaError.invalidConfiguration(reason: "Thread count must be positive")
        }
        
        guard config.maxTokens > 0 else {
            throw LlamaError.invalidConfiguration(reason: "Max tokens must be positive")
        }
        
        guard config.temperature >= 0.0 && config.temperature <= 2.0 else {
            throw LlamaError.invalidConfiguration(reason: "Temperature must be between 0.0 and 2.0")
        }
        
        guard config.contextSize > 0 else {
            throw LlamaError.invalidConfiguration(reason: "Context size must be positive")
        }
    }
    
    private func generateTokens(
        prompt: String,
        continuation: AsyncThrowingStream<LlamaToken, Error>.Continuation
    ) async throws {
        guard !prompt.isEmpty else {
            throw LlamaError.invalidPrompt
        }
        
        guard isModelLoaded else {
            throw LlamaError.modelLoadFailed(reason: "Model not loaded. Call loadModel() first.")
        }
        
        // TODO: Implement actual token generation loop
        // This is a placeholder implementation that would be replaced with
        // actual llama.cpp C API calls:
        //
        // 1. Tokenize prompt: llama_tokenize(...)
        // 2. Evaluate prompt: llama_decode(...)
        // 3. Sample tokens: llama_sampler_sample(...)
        // 4. Convert to string: llama_token_to_piece(...)
        // 5. Yield tokens through continuation
        
        // Placeholder: Generate a simple response token
        let placeholderToken = LlamaToken(
            text: "[Token generation not yet implemented - this is a placeholder]",
            id: 0,
            probability: 1.0
        )
        
        continuation.yield(placeholderToken)
        continuation.finish()
    }
    
    deinit {
        unloadModel()
    }
}
