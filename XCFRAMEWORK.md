# XCFramework Distribution Guide

This guide explains how to build and use the LlamaCppAdapter XCFramework for easier integration into iOS and macOS projects.

## What is XCFramework?

XCFramework is Apple's binary distribution format that bundles frameworks for multiple platforms and architectures into a single package. It provides:

- ✅ **Universal Support** - Single package for iOS device, iOS Simulator, and macOS
- ✅ **Pre-compiled Binary** - Faster build times in your projects
- ✅ **Easy Integration** - Drag-and-drop into Xcode projects
- ✅ **No SPM Required** - Works without Swift Package Manager
- ✅ **Version Control Friendly** - Binary releases on GitHub

## Building the XCFramework

### Prerequisites

- macOS 11.0 or later
- Xcode 14.0 or later
- Command Line Tools installed: `xcode-select --install`
- (Optional) xcpretty for better build output: `gem install xcpretty`

### Build Steps

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Sefito/llamaCppAdapter.git
   cd llamaCppAdapter
   ```

2. **Run the build script:**
   ```bash
   ./build-xcframework.sh
   ```

3. **Wait for the build to complete** (typically 5-15 minutes depending on your Mac)

4. **Find your XCFramework:**
   - Location: `xcframework/LlamaCppAdapter.xcframework`
   - ZIP archive: `xcframework/LlamaCppAdapter.xcframework.zip`
   - SHA256 checksum: `xcframework/LlamaCppAdapter.xcframework.zip.sha256`

### Build Script Options

The `build-xcframework.sh` script builds for all platforms by default:
- iOS device (arm64)
- iOS Simulator (arm64, x86_64)
- macOS (arm64, x86_64)

The script will:
1. Check prerequisites (Xcode, Swift)
2. Clean previous build artifacts
3. Build archives for each platform
4. Create the XCFramework
5. Generate ZIP and checksums
6. Display a summary

## Using the XCFramework

### Method 1: Manual Integration (Drag and Drop)

1. **Add to Xcode Project:**
   - Open your Xcode project
   - Drag `LlamaCppAdapter.xcframework` to your project navigator
   - Choose "Copy items if needed"
   - Select your app target

2. **Verify Integration:**
   - Select your project in the navigator
   - Select your app target
   - Go to "Frameworks, Libraries, and Embedded Content"
   - Ensure `LlamaCppAdapter.xcframework` is listed and set to "Embed & Sign"

3. **Import and Use:**
   ```swift
   import LlamaCppAdapter
   
   let runner = try LlamaRunner(modelPath: "/path/to/model.gguf")
   try await runner.loadModel()
   ```

### Method 2: CocoaPods (Future Support)

Create a podspec for distribution:

```ruby
Pod::Spec.new do |spec|
  spec.name         = "LlamaCppAdapter"
  spec.version      = "1.0.0"
  spec.summary      = "Swift adapter for llama.cpp"
  spec.homepage     = "https://github.com/Sefito/llamaCppAdapter"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "Your Name" => "your.email@example.com" }
  spec.platform     = :ios, "14.0"
  spec.source       = { 
    :http => "https://github.com/Sefito/llamaCppAdapter/releases/download/v1.0.0/LlamaCppAdapter.xcframework.zip",
    :sha256 => "YOUR_CHECKSUM_HERE"
  }
  spec.vendored_frameworks = "LlamaCppAdapter.xcframework"
end
```

### Method 3: Carthage (Future Support)

Add to your `Cartfile`:
```
binary "https://raw.githubusercontent.com/Sefito/llamaCppAdapter/main/LlamaCppAdapter.json"
```

### Method 4: Swift Package Manager (Still Recommended)

For source-based integration, continue using SPM:

```swift
dependencies: [
    .package(url: "https://github.com/Sefito/llamaCppAdapter", from: "1.0.0")
]
```

**Note:** SPM is still the recommended approach for most use cases as it provides automatic dependency management and stays up-to-date with the latest changes.

## Distributing Your XCFramework

### GitHub Releases

1. **Create a Release:**
   ```bash
   # Tag your version
   git tag -a v1.0.0 -m "Release 1.0.0 with XCFramework"
   git push origin v1.0.0
   ```

2. **Upload to GitHub:**
   - Go to your repository on GitHub
   - Click "Releases" → "Create a new release"
   - Choose your tag (v1.0.0)
   - Upload `LlamaCppAdapter.xcframework.zip`
   - Upload `LlamaCppAdapter.xcframework.zip.sha256`
   - Publish the release

3. **Users can download:**
   ```bash
   # Download the ZIP
   curl -L -o LlamaCppAdapter.xcframework.zip \
     https://github.com/Sefito/llamaCppAdapter/releases/download/v1.0.0/LlamaCppAdapter.xcframework.zip
   
   # Verify checksum
   shasum -a 256 -c LlamaCppAdapter.xcframework.zip.sha256
   
   # Extract
   unzip LlamaCppAdapter.xcframework.zip
   ```

### Binary Framework JSON (for Carthage)

Create `LlamaCppAdapter.json`:

```json
{
  "1.0.0": "https://github.com/Sefito/llamaCppAdapter/releases/download/v1.0.0/LlamaCppAdapter.xcframework.zip"
}
```

## XCFramework Structure

The built XCFramework contains:

```
LlamaCppAdapter.xcframework/
├── Info.plist                                    # Framework metadata
├── ios-arm64/                                    # iOS Device
│   └── LlamaCppAdapter.framework/
│       ├── LlamaCppAdapter                       # Binary
│       ├── Modules/
│       │   └── LlamaCppAdapter.swiftmodule/      # Swift interface
│       └── Headers/                              # Public headers
├── ios-arm64_x86_64-simulator/                   # iOS Simulator
│   └── LlamaCppAdapter.framework/
│       └── ...
└── macos-arm64_x86_64/                           # macOS
    └── LlamaCppAdapter.framework/
        └── ...
```

## Advantages and Disadvantages

### Advantages of XCFramework

✅ **Faster build times** - Pre-compiled, no need to build dependencies  
✅ **Smaller git repos** - No need to include source code  
✅ **Easy distribution** - Single file to distribute  
✅ **Version locking** - Explicit version control  
✅ **Binary releases** - Works without source access  

### Disadvantages of XCFramework

❌ **Large file size** - Binary frameworks are typically 50-200MB  
❌ **Manual updates** - Need to download new versions manually  
❌ **No source debugging** - Can't step into framework code  
❌ **Platform limitations** - Pre-built for specific architectures only  
❌ **Build complexity** - Requires macOS and Xcode to create  

### When to Use XCFramework

Use XCFramework when:
- Distributing commercial or closed-source frameworks
- Users need faster build times
- You want to hide implementation details
- Targeting non-SPM build systems

Use SPM when:
- You're actively developing or contributing
- You need source-level debugging
- You want automatic updates
- You prefer smaller repository sizes

## Integration Examples

### iOS App (UIKit)

```swift
import UIKit
import LlamaCppAdapter

class ViewController: UIViewController {
    private var runner: LlamaRunner?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Task {
            do {
                let modelURL = Bundle.main.url(forResource: "model", withExtension: "gguf")!
                runner = try LlamaRunner(modelURL: modelURL)
                try await runner?.loadModel()
            } catch {
                print("Error loading model: \(error)")
            }
        }
    }
    
    @IBAction func generateTapped(_ sender: UIButton) {
        guard let runner = runner else { return }
        
        Task {
            do {
                let response = try await runner.generate(from: "Once upon a time")
                print(response.text)
            } catch {
                print("Error generating: \(error)")
            }
        }
    }
}
```

### SwiftUI App

```swift
import SwiftUI
import LlamaCppAdapter

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var prompt = ""
    @State private var response = ""
    @StateObject private var model = LlamaModel()
    
    var body: some View {
        VStack {
            TextField("Prompt", text: $prompt)
            Button("Generate") {
                Task {
                    response = await model.generate(prompt: prompt)
                }
            }
            Text(response)
        }
        .padding()
    }
}

class LlamaModel: ObservableObject {
    private var runner: LlamaRunner?
    
    init() {
        Task {
            let modelURL = Bundle.main.url(forResource: "model", withExtension: "gguf")!
            runner = try? LlamaRunner(modelURL: modelURL)
            try? await runner?.loadModel()
        }
    }
    
    func generate(prompt: String) async -> String {
        guard let runner = runner else { return "Model not loaded" }
        do {
            let response = try await runner.generate(from: prompt)
            return response.text
        } catch {
            return "Error: \(error.localizedDescription)"
        }
    }
}
```

### macOS App

```swift
import AppKit
import LlamaCppAdapter

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    private var runner: LlamaRunner?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        Task {
            do {
                let modelURL = Bundle.main.url(forResource: "model", withExtension: "gguf")!
                runner = try LlamaRunner(modelURL: modelURL)
                try await runner?.loadModel()
                print("Model loaded successfully")
            } catch {
                print("Error: \(error)")
            }
        }
    }
}
```

## Troubleshooting

### Build Errors

**Error: "xcodebuild command not found"**
```bash
# Install Xcode Command Line Tools
xcode-select --install
```

**Error: "Scheme not found"**
```bash
# Ensure you're in the repository root
cd /path/to/llamaCppAdapter

# Resolve package dependencies first
swift package resolve
```

**Error: "Module llama not found"**
```bash
# The build script handles dependencies automatically
# If issues persist, try:
rm -rf .build
swift package resolve
./build-xcframework.sh
```

### Integration Errors

**Error: "dyld: Library not loaded"**
- Ensure the XCFramework is set to "Embed & Sign" in your target settings
- Check that the framework is in "Frameworks, Libraries, and Embedded Content"

**Error: "No such module 'LlamaCppAdapter'"**
- Clean build folder: Product → Clean Build Folder (⇧⌘K)
- Verify the framework is properly added to your target
- Restart Xcode

**Error: "Metal initialization failed"**
- Metal is not available in the iOS Simulator
- Use `.simulator` configuration preset for simulator builds
- Physical devices should work with Metal automatically

## Size Considerations

The XCFramework is relatively large due to:
- Multiple architectures (arm64, x86_64)
- Multiple platforms (iOS, iOS Simulator, macOS)
- Embedded llama.cpp library (C++ code)
- Metal shader resources

Expected sizes:
- XCFramework: ~100-300 MB uncompressed
- ZIP archive: ~30-100 MB compressed

To reduce size:
- Build only needed platforms (modify build script)
- Use aggressive optimization flags
- Strip debug symbols
- Consider separate frameworks per platform

## Continuous Integration

### GitHub Actions Example

Create `.github/workflows/build-xcframework.yml`:

```yaml
name: Build XCFramework

on:
  release:
    types: [created]
  workflow_dispatch:

jobs:
  build:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Select Xcode
      run: sudo xcode-select -s /Applications/Xcode.app
    
    - name: Build XCFramework
      run: ./build-xcframework.sh
    
    - name: Upload XCFramework
      uses: actions/upload-artifact@v3
      with:
        name: LlamaCppAdapter.xcframework
        path: xcframework/LlamaCppAdapter.xcframework.zip
    
    - name: Upload to Release
      if: github.event_name == 'release'
      uses: actions/upload-release-asset@v1
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      with:
        upload_url: ${{ github.event.release.upload_url }}
        asset_path: xcframework/LlamaCppAdapter.xcframework.zip
        asset_name: LlamaCppAdapter.xcframework.zip
        asset_content_type: application/zip
```

## Version Management

When releasing new versions:

1. Update version in relevant files
2. Build the XCFramework
3. Create a git tag
4. Create a GitHub release
5. Upload the XCFramework ZIP
6. Update checksum in distribution files

```bash
# Build new version
./build-xcframework.sh

# Tag and release
git tag -a v1.1.0 -m "Release 1.1.0"
git push origin v1.1.0

# Upload to GitHub release
# (Manual step or via GitHub Actions)
```

## Support and Resources

- **Repository**: https://github.com/Sefito/llamaCppAdapter
- **Issues**: https://github.com/Sefito/llamaCppAdapter/issues
- **Documentation**: See README.md and other docs in the repository
- **llama.cpp**: https://github.com/ggml-org/llama.cpp

## Next Steps

After building your XCFramework:

1. Test it in a sample project
2. Create a GitHub release
3. Share with your team or community
4. Consider creating CocoaPods/Carthage support
5. Set up automated builds with CI/CD

For questions or issues, please open an issue on GitHub!
