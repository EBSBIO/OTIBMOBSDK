#!/bin/bash

set -euo pipefail

if [[ $# -ne 1 || ! "${1:-}" =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 2.2"
    exit 1
fi

VERSION="$1"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_PATH="$ROOT_DIR/EbsSDKAdapter.xcodeproj"
PACKAGE_NAME="EbsSDKAdapter_$VERSION"

TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/EbsSDKAdapter.XXXXXX")"
DERIVED_DATA="$TEMP_DIR/DerivedData"
BUILD_DIR="$TEMP_DIR/$PACKAGE_NAME"
ARCHIVE_PATH="$ROOT_DIR/$PACKAGE_NAME.zip"

trap 'rm -rf "$TEMP_DIR"' EXIT

echo "Building EbsSDKAdapter $VERSION for iOS..."

xcodebuild build \
    -project "$PROJECT_PATH" \
    -scheme EbsSDKAdapter \
    -configuration Release \
    -sdk iphoneos \
    -destination "generic/platform=iOS" \
    -derivedDataPath "$DERIVED_DATA" \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    CODE_SIGNING_ALLOWED=NO

echo "Building EbsSDKAdapter $VERSION for Simulator..."

xcodebuild build \
    -project "$PROJECT_PATH" \
    -scheme EbsSDKAdapter \
    -configuration Release \
    -sdk iphonesimulator \
    -destination "generic/platform=iOS Simulator" \
    -derivedDataPath "$DERIVED_DATA" \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    CODE_SIGNING_ALLOWED=NO \
    ONLY_ACTIVE_ARCH=NO \
    ARCHS="arm64 x86_64"

DEVICE_FRAMEWORK="$DERIVED_DATA/Build/Products/Release-iphoneos/EbsSDKAdapter.framework"
SIMULATOR_FRAMEWORK="$DERIVED_DATA/Build/Products/Release-iphonesimulator/EbsSDKAdapter.framework"

for framework in "$DEVICE_FRAMEWORK" "$SIMULATOR_FRAMEWORK"; do
    if [[ ! -f "$framework/EbsSDKAdapter" ]]; then
        echo "Error: framework binary not found: $framework"
        exit 1
    fi
done

mkdir -p \
    "$BUILD_DIR/iphoneos" \
    "$BUILD_DIR/iphonesimulator" \
    "$BUILD_DIR/universal" \
    "$BUILD_DIR/XC"

ditto "$DEVICE_FRAMEWORK" \
    "$BUILD_DIR/iphoneos/EbsSDKAdapter.framework"

ditto "$SIMULATOR_FRAMEWORK" \
    "$BUILD_DIR/iphonesimulator/EbsSDKAdapter.framework"

echo "Creating legacy universal framework..."

UNIVERSAL_FRAMEWORK="$BUILD_DIR/universal/EbsSDKAdapter.framework"
SIMULATOR_X86_BINARY="$TEMP_DIR/EbsSDKAdapter-simulator-x86_64"

ditto "$DEVICE_FRAMEWORK" "$UNIVERSAL_FRAMEWORK"

# Device arm64 and Simulator arm64 cannot coexist in a fat binary.
# Keep the complete Simulator framework separately and use x86_64 here.
lipo "$SIMULATOR_FRAMEWORK/EbsSDKAdapter" \
    -thin x86_64 \
    -output "$SIMULATOR_X86_BINARY"

lipo -create \
    "$DEVICE_FRAMEWORK/EbsSDKAdapter" \
    "$SIMULATOR_X86_BINARY" \
    -output "$UNIVERSAL_FRAMEWORK/EbsSDKAdapter"

ditto "$SIMULATOR_FRAMEWORK/Modules" \
    "$UNIVERSAL_FRAMEWORK/Modules"

echo "Creating XCFramework..."

xcodebuild -create-xcframework \
    -framework "$BUILD_DIR/iphoneos/EbsSDKAdapter.framework" \
    -framework "$BUILD_DIR/iphonesimulator/EbsSDKAdapter.framework" \
    -output "$BUILD_DIR/XC/EbsSDKAdapter.xcframework"

echo "Creating archive..."

(
    cd "$TEMP_DIR"
    zip -r -q "$PACKAGE_NAME.zip" "$PACKAGE_NAME"
)

mv -f "$TEMP_DIR/$PACKAGE_NAME.zip" "$ARCHIVE_PATH"

echo "Done: $ARCHIVE_PATH"