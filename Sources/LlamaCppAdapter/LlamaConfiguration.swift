import Foundation

/// Configuration for Llama model inference
public struct LlamaConfiguration {
    /// Number of threads to use for inference
    public let threads: Int
    
    /// Maximum number of tokens to generate
    public let maxTokens: Int
    
    /// Temperature for sampling (0.0 to 2.0)
    public let temperature: Float
    
    /// Top-p sampling parameter
    public let topP: Float
    
    /// Top-k sampling parameter
    public let topK: Int
    
    /// Context size (number of tokens in context window)
    public let contextSize: Int
    
    /// Batch size for prompt processing
    public let batchSize: Int
    
    /// Enable Metal GPU acceleration
    public let useMetalAcceleration: Bool
    
    /// Stop tokens to terminate generation
    public let stopTokens: [String]
    
    /// Initialize with default values optimized for iOS
    public init(
        threads: Int = ProcessInfo.processInfo.processorCount,
        maxTokens: Int = 512,
        temperature: Float = 0.7,
        topP: Float = 0.95,
        topK: Int = 40,
        contextSize: Int = 2048,
        batchSize: Int = 512,
        useMetalAcceleration: Bool = true,
        stopTokens: [String] = []
    ) {
        self.threads = threads
        self.maxTokens = maxTokens
        self.temperature = temperature
        self.topP = topP
        self.topK = topK
        self.contextSize = contextSize
        self.batchSize = batchSize
        self.useMetalAcceleration = useMetalAcceleration
        self.stopTokens = stopTokens
    }
    
    /// Preset for low memory devices (iPhone with limited RAM)
    public static var lowMemory: LlamaConfiguration {
        LlamaConfiguration(
            threads: 4,
            maxTokens: 256,
            contextSize: 1024,
            batchSize: 256
        )
    }
    
    /// Preset for high performance devices
    public static var highPerformance: LlamaConfiguration {
        LlamaConfiguration(
            threads: ProcessInfo.processInfo.processorCount,
            maxTokens: 1024,
            contextSize: 4096,
            batchSize: 512
        )
    }
    
    /// Preset for simulator testing
    public static var simulator: LlamaConfiguration {
        LlamaConfiguration(
            threads: 2,
            maxTokens: 128,
            contextSize: 512,
            batchSize: 128,
            useMetalAcceleration: false
        )
    }
}
