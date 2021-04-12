	
VERSION=$1 1
DERIVED_DATA="derived_data"
BUILD_DIR="./EbsSDKAdapter_$VERSION"

rm -rf $DERIVED_DATA
rm -rf $BUILD_DIR

xcodebuild build -scheme EbsSDKAdapter -sdk iphoneos -configuration Release -derivedDataPath $DERIVED_DATA BUILD_LIBRARY_FOR_DISTRIBUTION=YES
xcodebuild build -scheme EbsSDKAdapter -sdk iphonesimulator -configuration Release -derivedDataPath $DERIVED_DATA BUILD_LIBRARY_FOR_DISTRIBUTION=YES

mkdir -p $BUILD_DIR/iphoneos/EbsSDKAdapter.framework/
cp -r $DERIVED_DATA/Build/Products/Release-iphoneos/* $BUILD_DIR/iphoneos

mkdir -p $BUILD_DIR/iphonesimulator/EbsSDKAdapter.framework/
cp -r $DERIVED_DATA/Build/Products/Release-iphonesimulator/* $BUILD_DIR/iphonesimulator
lipo -remove arm64 $BUILD_DIR/iphonesimulator/EbsSDKAdapter.framework/EbsSDKAdapter -o $BUILD_DIR/iphonesimulator/EbsSDKAdapter.framework/EbsSDKAdapter 

mkdir -p $BUILD_DIR/universal/EbsSDKAdapter.framework/
cp -r $DERIVED_DATA/Build/Products/Release-iphoneos/* $BUILD_DIR/universal
lipo -create \
	$BUILD_DIR/iphoneos/EbsSDKAdapter.framework/EbsSDKAdapter \
	$BUILD_DIR/iphonesimulator/EbsSDKAdapter.framework/EbsSDKAdapter \
	-o $BUILD_DIR/universal/EbsSDKAdapter.framework/EbsSDKAdapter

mkdir -p $BUILD_DIR/XC
xcodebuild -create-xcframework \
    -framework $BUILD_DIR/iphoneos/EbsSDKAdapter.framework \
    -framework $BUILD_DIR/iphonesimulator/EbsSDKAdapter.framework \
    -output $BUILD_DIR/XC/EbsSDKAdapter.xcframework

zip -r $BUILD_DIR.zip $BUILD_DIR
