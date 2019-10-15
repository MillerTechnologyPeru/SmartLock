# Package
echo "Copying Debian package files"
rm -rf ./lockd/usr
mkdir ./lockd/usr
mkdir ./lockd/usr/bin
cp -rf ../.build/release/lockd ./lockd/usr/bin/
mkdir ./lockd/usr/lib
mkdir ./lockd/usr/lib/swift
cp -rf ../.build/release/libBluetooth.so ./lockd/usr/lib/swift/
cp -rf ../.build/release/libGATT.so ./lockd/usr/lib/swift/
cp -rf ../.build/release/libTLVCoding.so ./lockd/usr/lib/swift/

echo "Building Debian package"
dpkg-deb -b lockd lockd.deb
