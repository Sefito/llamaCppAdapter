import Foundation

/// Utility functions for LlamaCppAdapter
public enum LlamaUtilities {
    
    /// Check if Metal acceleration is available on the current device
    public static var isMetalAvailable: Bool {
        #if os(iOS) || os(macOS)
        if #available(iOS 13.0, macOS 10.15, *) {
            return MTLCreateSystemDefaultDevice() != nil
        }
        return false
        #else
        return false
        #endif
    }
    
    /// Get recommended configuration for current device
    public static func recommendedConfiguration() -> LlamaConfiguration {
        #if targetEnvironment(simulator)
        return .simulator
        #else
        let physicalMemory = ProcessInfo.processInfo.physicalMemory
        let availableMemoryGB = Double(physicalMemory) / 1_073_741_824.0 // Convert to GB
        
        // Recommend configuration based on available memory
        if availableMemoryGB < 4.0 {
            return .lowMemory
        } else if availableMemoryGB >= 8.0 {
            return .highPerformance
        } else {
            return LlamaConfiguration()
        }
        #endif
    }
    
    /// Validate GGUF model file format
    /// - Parameter url: URL to the model file
    /// - Returns: True if the file appears to be a valid GGUF file
    public static func isValidGGUFModel(at url: URL) -> Bool {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return false
        }
        
        // Check file extension
        let validExtensions = ["gguf", "bin"]
        guard validExtensions.contains(url.pathExtension.lowercased()) else {
            return false
        }
        
        // Check GGUF magic number (first 4 bytes should be "GGUF" for GGUF format)
        guard let fileHandle = try? FileHandle(forReadingFrom: url) else {
            return false
        }
        
        defer {
            try? fileHandle.close()
        }
        
        guard let magicBytes = try? fileHandle.read(upToCount: 4),
              magicBytes.count == 4 else {
            return false
        }
        
        // GGUF magic: 0x47475546 (ASCII "GGUF")
        let ggufMagic = Data([0x47, 0x47, 0x55, 0x46])
        
        return magicBytes == ggufMagic
    }
    
    /// Format bytes to human-readable string
    public static func formatBytes(_ bytes: Int) -> String {
        let units = ["B", "KB", "MB", "GB", "TB"]
        var value = Double(bytes)
        var unitIndex = 0
        
        while value >= 1024.0 && unitIndex < units.count - 1 {
            value /= 1024.0
            unitIndex += 1
        }
        
        return String(format: "%.2f %@", value, units[unitIndex])
    }
    
    /// Get model file size
    public static func getModelSize(at url: URL) -> Int? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attributes[.size] as? Int else {
            return nil
        }
        return fileSize
    }
}

#if os(iOS) || os(macOS)
import Metal

extension LlamaUtilities {
    /// Get Metal device information
    public static func getMetalDeviceInfo() -> String? {
        guard let device = MTLCreateSystemDefaultDevice() else {
            return nil
        }
        
        var info = "Metal Device: \(device.name)\n"
        info += "Max threads per threadgroup: \(device.maxThreadsPerThreadgroup)\n"
        
        if #available(iOS 14.0, macOS 11.0, *) {
            info += "Supports dynamic libraries: \(device.supportsDynamicLibraries)\n"
        }
        
        return info
    }
}
#endif
