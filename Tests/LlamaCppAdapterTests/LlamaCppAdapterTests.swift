import XCTest
@testable import LlamaCppAdapter

@available(iOS 14.0, macOS 11.0, *)
final class LlamaCppAdapterTests: XCTestCase {
    
    // MARK: - Configuration Tests
    
    func testDefaultConfiguration() {
        let config = LlamaConfiguration()
        
        XCTAssertGreaterThan(config.threads, 0)
        XCTAssertEqual(config.maxTokens, 512)
        XCTAssertEqual(config.temperature, 0.7)
        XCTAssertEqual(config.contextSize, 2048)
        XCTAssertTrue(config.useMetalAcceleration)
    }
    
    func testLowMemoryConfiguration() {
        let config = LlamaConfiguration.lowMemory
        
        XCTAssertEqual(config.threads, 4)
        XCTAssertEqual(config.maxTokens, 256)
        XCTAssertEqual(config.contextSize, 1024)
    }
    
    func testHighPerformanceConfiguration() {
        let config = LlamaConfiguration.highPerformance
        
        XCTAssertGreaterThan(config.threads, 0)
        XCTAssertEqual(config.maxTokens, 1024)
        XCTAssertEqual(config.contextSize, 4096)
    }
    
    func testSimulatorConfiguration() {
        let config = LlamaConfiguration.simulator
        
        XCTAssertEqual(config.threads, 2)
        XCTAssertEqual(config.maxTokens, 128)
        XCTAssertEqual(config.contextSize, 512)
        XCTAssertFalse(config.useMetalAcceleration)
    }
    
    // MARK: - Error Tests
    
    func testModelNotFoundError() {
        let error = LlamaError.modelNotFound(path: "/invalid/path")
        
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("/invalid/path"))
        XCTAssertNotNil(error.recoverySuggestion)
    }
    
    func testInvalidConfigurationError() {
        let error = LlamaError.invalidConfiguration(reason: "Invalid threads")
        
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("Invalid threads"))
    }
    
    // MARK: - Type Tests
    
    func testLlamaTokenCreation() {
        let token = LlamaToken(text: "Hello", id: 123, probability: 0.95)
        
        XCTAssertEqual(token.text, "Hello")
        XCTAssertEqual(token.id, 123)
        XCTAssertEqual(token.probability, 0.95)
    }
    
    func testLlamaResponseCreation() {
        let response = LlamaResponse(
            text: "Generated text",
            tokenCount: 10,
            generationTime: 2.0
        )
        
        XCTAssertEqual(response.text, "Generated text")
        XCTAssertEqual(response.tokenCount, 10)
        XCTAssertEqual(response.generationTime, 2.0)
        XCTAssertEqual(response.tokensPerSecond, 5.0)
    }
    
    func testLlamaModelInfoCreation() {
        let info = LlamaModelInfo(
            architecture: "llama",
            parameterCount: 7_000_000_000,
            contextLength: 4096,
            vocabularySize: 32000,
            quantizationType: "Q4_0"
        )
        
        XCTAssertEqual(info.architecture, "llama")
        XCTAssertEqual(info.parameterCount, 7_000_000_000)
        XCTAssertEqual(info.contextLength, 4096)
        XCTAssertEqual(info.vocabularySize, 32000)
        XCTAssertEqual(info.quantizationType, "Q4_0")
    }
    
    // MARK: - Utility Tests
    
    func testMetalAvailability() {
        // This test just ensures the function doesn't crash
        let _ = LlamaUtilities.isMetalAvailable
    }
    
    func testRecommendedConfiguration() {
        let config = LlamaUtilities.recommendedConfiguration()
        
        XCTAssertGreaterThan(config.threads, 0)
        XCTAssertGreaterThan(config.maxTokens, 0)
        XCTAssertGreaterThan(config.contextSize, 0)
    }
    
    func testFormatBytes() {
        XCTAssertEqual(LlamaUtilities.formatBytes(0), "0.00 B")
        XCTAssertEqual(LlamaUtilities.formatBytes(1024), "1.00 KB")
        XCTAssertEqual(LlamaUtilities.formatBytes(1024 * 1024), "1.00 MB")
        XCTAssertEqual(LlamaUtilities.formatBytes(1024 * 1024 * 1024), "1.00 GB")
    }
    
    func testIsValidGGUFModel() {
        // Test with non-existent file
        let url = URL(fileURLWithPath: "/non/existent/model.gguf")
        XCTAssertFalse(LlamaUtilities.isValidGGUFModel(at: url))
    }
    
    // MARK: - Runner Tests
    
    func testRunnerInitializationWithInvalidPath() {
        XCTAssertThrowsError(try LlamaRunner(modelPath: "/invalid/path/model.gguf")) { error in
            guard case LlamaError.modelNotFound = error else {
                XCTFail("Expected modelNotFound error")
                return
            }
        }
    }
    
    func testRunnerInitializationWithInvalidConfiguration() {
        // Create a temporary file for testing
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_model.gguf")
        _ = FileManager.default.createFile(atPath: tempURL.path, contents: Data())
        defer { try? FileManager.default.removeItem(at: tempURL) }
        
        // Test with invalid configuration
        let invalidConfig = LlamaConfiguration(
            threads: -1,  // Invalid
            maxTokens: 512
        )
        
        XCTAssertThrowsError(try LlamaRunner(modelURL: tempURL, configuration: invalidConfig)) { error in
            guard case LlamaError.invalidConfiguration = error else {
                XCTFail("Expected invalidConfiguration error")
                return
            }
        }
    }
    
    func testRunnerGenerateWithoutLoading() async {
        // Create a temporary file for testing
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_model.gguf")
        _ = FileManager.default.createFile(atPath: tempURL.path, contents: Data())
        defer { try? FileManager.default.removeItem(at: tempURL) }
        
        let runner = try! LlamaRunner(modelURL: tempURL)
        
        // Try to generate without loading
        do {
            _ = try await runner.generate(from: "test")
            XCTFail("Should have thrown an error")
        } catch LlamaError.modelLoadFailed(let reason) {
            XCTAssertTrue(reason.contains("not loaded"))
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
}
