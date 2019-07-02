# Set Swift Path
export PATH=/opt/colemancda/swift/usr/bin:"${PATH}"

# Build
echo "Building lockd"
cd ../
rm -rf .build
swift build --configuration release

# Package
echo "Copying Debian package files"
cp -rf .build/armv7-unknown-linux-gnueabihf/release/lockd ./debianpackage/lockd/usr/bin/
cd ./debianpackage
