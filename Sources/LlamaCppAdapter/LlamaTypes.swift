import Foundation

/// Represents a token generated during inference
public struct LlamaToken: Sendable {
    /// The token text
    public let text: String
    
    /// The token ID
    public let id: Int32
    
    /// Probability/logit of this token
    public let probability: Float?
    
    public init(text: String, id: Int32, probability: Float? = nil) {
        self.text = text
        self.id = id
        self.probability = probability
    }
}

/// Response from a complete generation
public struct LlamaResponse: Sendable {
    /// The generated text
    public let text: String
    
    /// Number of tokens generated
    public let tokenCount: Int
    
    /// Time taken for generation (in seconds)
    public let generationTime: TimeInterval
    
    /// Tokens per second
    public var tokensPerSecond: Double {
        generationTime > 0 ? Double(tokenCount) / generationTime : 0
    }
    
    public init(text: String, tokenCount: Int, generationTime: TimeInterval) {
        self.text = text
        self.tokenCount = tokenCount
        self.generationTime = generationTime
    }
}

/// Model information and metadata
public struct LlamaModelInfo: Sendable {
    /// Model architecture (e.g., "llama", "mistral")
    public let architecture: String?
    
    /// Total number of parameters
    public let parameterCount: Int?
    
    /// Context size limit
    public let contextLength: Int?
    
    /// Vocabulary size
    public let vocabularySize: Int?
    
    /// Model quantization type (e.g., "Q4_0", "Q8_0")
    public let quantizationType: String?
    
    public init(
        architecture: String? = nil,
        parameterCount: Int? = nil,
        contextLength: Int? = nil,
        vocabularySize: Int? = nil,
        quantizationType: String? = nil
    ) {
        self.architecture = architecture
        self.parameterCount = parameterCount
        self.contextLength = contextLength
        self.vocabularySize = vocabularySize
        self.quantizationType = quantizationType
    }
}
