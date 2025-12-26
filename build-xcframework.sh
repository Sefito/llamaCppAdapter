#!/bin/bash

# XCFramework Build Script for LlamaCppAdapter
# This script builds a universal XCFramework for iOS (device + simulator) and macOS
# Requirements: macOS with Xcode 14.0+

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
FRAMEWORK_NAME="LlamaCppAdapter"
BUILD_DIR="build"
XCFRAMEWORK_DIR="xcframework"
DERIVED_DATA_PATH="${BUILD_DIR}/DerivedData"

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "This script must be run on macOS"
        exit 1
    fi
    
    if ! command -v xcodebuild &> /dev/null; then
        print_error "xcodebuild not found. Please install Xcode."
        exit 1
    fi
    
    if ! command -v swift &> /dev/null; then
        print_error "swift not found. Please install Xcode."
        exit 1
    fi
    
    print_info "Prerequisites check passed ✓"
}

# Function to clean build artifacts
clean_build() {
    print_info "Cleaning previous build artifacts..."
    rm -rf "${BUILD_DIR}"
    rm -rf "${XCFRAMEWORK_DIR}"
    mkdir -p "${BUILD_DIR}"
    mkdir -p "${XCFRAMEWORK_DIR}"
    print_info "Clean complete ✓"
}

# Function to build for a specific platform and architecture
build_framework() {
    local sdk=$1
    local destination=$2
    local archive_path=$3
    local platform_name=$4
    
    print_info "Building ${FRAMEWORK_NAME} for ${platform_name}..."
    
    xcodebuild archive \
        -scheme ${FRAMEWORK_NAME} \
        -sdk ${sdk} \
        -destination "${destination}" \
        -archivePath "${archive_path}" \
        -derivedDataPath "${DERIVED_DATA_PATH}" \
        SKIP_INSTALL=NO \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        SWIFT_SERIALIZE_DEBUGGING_OPTIONS=NO \
        | xcpretty || true
    
    if [ $? -eq 0 ]; then
        print_info "${platform_name} build complete ✓"
    else
        print_error "${platform_name} build failed"
        exit 1
    fi
}

# Function to create XCFramework
create_xcframework() {
    print_info "Creating XCFramework..."
    
    local ios_device_archive="${BUILD_DIR}/ios-device.xcarchive"
    local ios_simulator_archive="${BUILD_DIR}/ios-simulator.xcarchive"
    local macos_archive="${BUILD_DIR}/macos.xcarchive"
    local xcframework_path="${XCFRAMEWORK_DIR}/${FRAMEWORK_NAME}.xcframework"
    
    # Build framework archives for each platform
    build_framework \
        "iphoneos" \
        "generic/platform=iOS" \
        "${ios_device_archive}" \
        "iOS Device"
    
    build_framework \
        "iphonesimulator" \
        "generic/platform=iOS Simulator" \
        "${ios_simulator_archive}" \
        "iOS Simulator"
    
    build_framework \
        "macosx" \
        "generic/platform=macOS" \
        "${macos_archive}" \
        "macOS"
    
    # Create XCFramework
    print_info "Packaging XCFramework..."
    
    xcodebuild -create-xcframework \
        -framework "${ios_device_archive}/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" \
        -framework "${ios_simulator_archive}/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" \
        -framework "${macos_archive}/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" \
        -output "${xcframework_path}"
    
    if [ $? -eq 0 ]; then
        print_info "XCFramework created successfully ✓"
        print_info "Location: ${xcframework_path}"
    else
        print_error "XCFramework creation failed"
        exit 1
    fi
}

# Function to generate checksums
generate_checksums() {
    print_info "Generating checksums..."
    
    local xcframework_path="${XCFRAMEWORK_DIR}/${FRAMEWORK_NAME}.xcframework"
    
    if [ -d "${xcframework_path}" ]; then
        cd "${XCFRAMEWORK_DIR}"
        
        # Create ZIP for distribution
        print_info "Creating ZIP archive..."
        zip -r -q "${FRAMEWORK_NAME}.xcframework.zip" "${FRAMEWORK_NAME}.xcframework"
        
        # Generate SHA256 checksum
        if command -v shasum &> /dev/null; then
            shasum -a 256 "${FRAMEWORK_NAME}.xcframework.zip" > "${FRAMEWORK_NAME}.xcframework.zip.sha256"
            print_info "SHA256 checksum: $(cat ${FRAMEWORK_NAME}.xcframework.zip.sha256)"
        fi
        
        cd ..
        print_info "Checksums generated ✓"
    else
        print_warning "XCFramework not found, skipping checksum generation"
    fi
}

# Function to display summary
display_summary() {
    local xcframework_path="${XCFRAMEWORK_DIR}/${FRAMEWORK_NAME}.xcframework"
    local zip_path="${XCFRAMEWORK_DIR}/${FRAMEWORK_NAME}.xcframework.zip"
    
    print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_info "Build Summary"
    print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if [ -d "${xcframework_path}" ]; then
        echo "✓ XCFramework: ${xcframework_path}"
        
        # Display supported platforms
        print_info "Supported Platforms:"
        find "${xcframework_path}" -name "*.framework" -type d | while read framework; do
            echo "  - $(basename $(dirname ${framework}))"
        done
    fi
    
    if [ -f "${zip_path}" ]; then
        echo "✓ ZIP Archive: ${zip_path}"
        echo "  Size: $(du -h ${zip_path} | cut -f1)"
    fi
    
    print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_info "To use the XCFramework:"
    echo "  1. Drag ${FRAMEWORK_NAME}.xcframework to your Xcode project"
    echo "  2. Or use the ZIP file for distribution"
    echo "  3. See XCFRAMEWORK.md for detailed integration instructions"
    print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Main execution
main() {
    print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_info "Building XCFramework for ${FRAMEWORK_NAME}"
    print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    check_prerequisites
    clean_build
    create_xcframework
    generate_checksums
    display_summary
    
    print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_info "Build completed successfully! ✓"
    print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Check if xcpretty is installed, if not suggest it
if ! command -v xcpretty &> /dev/null; then
    print_warning "xcpretty not found. Install it for better build output:"
    print_warning "  gem install xcpretty"
fi

# Run main function
main
