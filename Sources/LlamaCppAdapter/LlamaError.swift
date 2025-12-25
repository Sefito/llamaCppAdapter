import Foundation

/// Errors that can occur during Llama model operations
public enum LlamaError: LocalizedError {
    case modelNotFound(path: String)
    case modelLoadFailed(reason: String)
    case contextCreationFailed
    case invalidConfiguration(reason: String)
    case inferenceError(reason: String)
    case invalidPrompt
    case resourceExhausted(reason: String)
    case metalNotAvailable
    
    public var errorDescription: String? {
        switch self {
        case .modelNotFound(let path):
            return "Model file not found at path: \(path)"
        case .modelLoadFailed(let reason):
            return "Failed to load model: \(reason)"
        case .contextCreationFailed:
            return "Failed to create inference context"
        case .invalidConfiguration(let reason):
            return "Invalid configuration: \(reason)"
        case .inferenceError(let reason):
            return "Inference error: \(reason)"
        case .invalidPrompt:
            return "Invalid or empty prompt provided"
        case .resourceExhausted(let reason):
            return "Resource exhausted: \(reason)"
        case .metalNotAvailable:
            return "Metal acceleration is not available on this device"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .modelNotFound:
            return "Ensure the model file exists at the specified path and is accessible"
        case .modelLoadFailed:
            return "Verify the model file is a valid GGUF format and not corrupted"
        case .contextCreationFailed:
            return "Try reducing the context size in the configuration"
        case .invalidConfiguration:
            return "Review and adjust the configuration parameters"
        case .inferenceError:
            return "Check model compatibility and input format"
        case .invalidPrompt:
            return "Provide a non-empty prompt string"
        case .resourceExhausted:
            return "Try using a smaller model or reduce context size"
        case .metalNotAvailable:
            return "Disable Metal acceleration in configuration or use a device with Metal support"
        }
    }
}
