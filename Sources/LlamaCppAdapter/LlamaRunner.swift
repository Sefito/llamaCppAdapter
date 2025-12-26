import Foundation
import llama

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
    
    // Native llama.cpp model and context pointers
    private var modelPointer: OpaquePointer?
    private var contextPointer: OpaquePointer?
    private var samplerPointer: UnsafeMutablePointer<llama_sampler>?
    
    // Backend initialization flag
    private static var backendInitialized = false
    private static let backendLock = NSLock()
    
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
        
        // Initialize backend once
        Self.backendLock.lock()
        if !Self.backendInitialized {
            llama_backend_init()
            Self.backendInitialized = true
        }
        Self.backendLock.unlock()
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
                
                do {
                    // Configure model parameters
                    var modelParams = llama_model_default_params()
                    modelParams.n_gpu_layers = self.configuration.useMetalAcceleration ? 999 : 0
                    modelParams.use_mmap = true
                    
                    // Load model
                    guard let model = llama_load_model_from_file(
                        self.modelURL.path.cString(using: .utf8),
                        modelParams
                    ) else {
                        continuation.resume(throwing: LlamaError.modelLoadFailed(
                            reason: "Failed to load model from file"
                        ))
                        return
                    }
                    self.modelPointer = model
                    
                    // Configure context parameters
                    var contextParams = llama_context_default_params()
                    contextParams.n_ctx = UInt32(self.configuration.contextSize)
                    contextParams.n_batch = UInt32(self.configuration.batchSize)
                    contextParams.n_threads = Int32(self.configuration.threads)
                    contextParams.n_threads_batch = Int32(self.configuration.threads)
                    
                    // Create context
                    guard let context = llama_new_context_with_model(model, contextParams) else {
                        llama_free_model(model)
                        self.modelPointer = nil
                        continuation.resume(throwing: LlamaError.modelLoadFailed(
                            reason: "Failed to create context"
                        ))
                        return
                    }
                    self.contextPointer = context
                    
                    // Create sampler
                    var samplerParams = llama_sampler_chain_default_params()
                    samplerParams.no_perf = false
                    
                    guard let sampler = llama_sampler_chain_init(samplerParams) else {
                        llama_free(context)
                        llama_free_model(model)
                        self.modelPointer = nil
                        self.contextPointer = nil
                        continuation.resume(throwing: LlamaError.modelLoadFailed(
                            reason: "Failed to create sampler"
                        ))
                        return
                    }
                    self.samplerPointer = sampler
                    
                    // Add sampling strategies
                    llama_sampler_chain_add(sampler, llama_sampler_init_top_k(Int32(self.configuration.topK)))
                    llama_sampler_chain_add(sampler, llama_sampler_init_top_p(self.configuration.topP, 1))
                    llama_sampler_chain_add(sampler, llama_sampler_init_temp(self.configuration.temperature))
                    llama_sampler_chain_add(sampler, llama_sampler_init_dist(UInt32(LLAMA_DEFAULT_SEED)))
                    
                    self.isModelLoaded = true
                    continuation.resume()
                }
            }
        }
    }
    
    /// Unload the model from memory
    public func unloadModel() {
        queue.sync {
            if let sampler = samplerPointer {
                llama_sampler_free(sampler)
                samplerPointer = nil
            }
            
            if let context = contextPointer {
                llama_free(context)
                contextPointer = nil
            }
            
            if let model = modelPointer {
                llama_free_model(model)
                modelPointer = nil
            }
            
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
        guard isModelLoaded, let model = modelPointer else { return nil }
        
        // Get model metadata
        let nVocab = llama_n_vocab(model)
        let nCtxTrain = llama_n_ctx_train(model)
        
        // Get architecture name
        var archBuf = [CChar](repeating: 0, count: 128)
        llama_model_meta_val_str(model, "general.architecture", &archBuf, 128)
        let architecture = String(cString: archBuf)
        
        // Get parameter count if available
        var paramCountBuf = [CChar](repeating: 0, count: 64)
        let paramCountResult = llama_model_meta_val_str(model, "general.parameter_count", &paramCountBuf, 64)
        let parameterCount: Int? = paramCountResult > 0 ? Int(String(cString: paramCountBuf)) : nil
        
        // Get quantization type
        var quantBuf = [CChar](repeating: 0, count: 64)
        llama_model_meta_val_str(model, "general.file_type", &quantBuf, 64)
        let quantization = String(cString: quantBuf)
        
        return LlamaModelInfo(
            architecture: architecture.isEmpty ? nil : architecture,
            parameterCount: parameterCount,
            contextLength: Int(nCtxTrain),
            vocabularySize: Int(nVocab),
            quantizationType: quantization.isEmpty ? nil : quantization
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
        
        guard isModelLoaded, let model = modelPointer, let context = contextPointer, let sampler = samplerPointer else {
            throw LlamaError.modelLoadFailed(reason: "Model not loaded. Call loadModel() first.")
        }
        
        // Tokenize the prompt
        let nPromptTokens = -llama_tokenize(model, prompt, Int32(prompt.utf8.count), nil, 0, true, false)
        guard nPromptTokens > 0 else {
            continuation.finish(throwing: LlamaError.invalidPrompt)
            return
        }
        
        var promptTokens = [llama_token](repeating: 0, count: Int(nPromptTokens))
        let actualTokenCount = llama_tokenize(
            model,
            prompt,
            Int32(prompt.utf8.count),
            &promptTokens,
            Int32(promptTokens.count),
            true,
            false
        )
        
        guard actualTokenCount == nPromptTokens else {
            continuation.finish(throwing: LlamaError.modelLoadFailed(reason: "Tokenization mismatch"))
            return
        }
        
        // Clear the context
        llama_kv_cache_clear(context)
        
        // Create batch for prompt processing
        var batch = llama_batch_init(Int32(promptTokens.count), 0, 1)
        defer { 
            llama_batch_free(batch) 
        }
        
        // Add prompt tokens to batch
        for (i, token) in promptTokens.enumerated() {
            batch.token[i] = token
            batch.pos[i] = Int32(i)
            batch.n_seq_id[i] = 1
            batch.seq_id[i]![0] = 0
            batch.logits[i] = 0
        }
        batch.n_tokens = Int32(promptTokens.count)
        
        // Ensure the last token generates logits
        if batch.n_tokens > 0 {
            batch.logits[Int(batch.n_tokens) - 1] = 1
        }
        
        // Process prompt
        if llama_decode(context, batch) != 0 {
            continuation.finish(throwing: LlamaError.modelLoadFailed(reason: "Failed to decode prompt"))
            return
        }
        
        // Reset sampler
        llama_sampler_reset(sampler)
        
        // Generate tokens
        var nCur = batch.n_tokens
        var nDecode = 0
        let maxTokens = Int32(configuration.maxTokens)
        
        while nDecode < maxTokens {
            // Sample next token
            let newTokenId = llama_sampler_sample(sampler, context, -1)
            
            // Check for end of generation
            if llama_token_is_eog(model, newTokenId) {
                break
            }
            
            // Convert token to text
            var tokenBuf = [CChar](repeating: 0, count: 256)
            let tokenLen = llama_token_to_piece(model, newTokenId, &tokenBuf, 256, 0, false)
            
            if tokenLen > 0 {
                let tokenText = String(cString: tokenBuf)
                
                // Check for stop tokens
                var shouldStop = false
                for stopToken in configuration.stopTokens {
                    if tokenText.contains(stopToken) {
                        shouldStop = true
                        break
                    }
                }
                
                if shouldStop {
                    break
                }
                
                // Yield the token
                let token = LlamaToken(text: tokenText, id: newTokenId, probability: nil)
                continuation.yield(token)
            }
            
            // Prepare batch for next token
            batch.n_tokens = 1
            batch.token[0] = newTokenId
            batch.pos[0] = nCur
            batch.n_seq_id[0] = 1
            batch.seq_id[0]![0] = 0
            batch.logits[0] = 1
            
            nCur += 1
            nDecode += 1
            
            // Decode next token
            if llama_decode(context, batch) != 0 {
                continuation.finish(throwing: LlamaError.modelLoadFailed(reason: "Failed to decode token"))
                return
            }
        }
        
        continuation.finish()
    }
    
    deinit {
        unloadModel()
    }
}
