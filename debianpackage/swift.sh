# Set Swift Path
export PATH=/opt/colemancda/swift/usr/bin:"${PATH}"

# Install Swift
tar xvf swift.tar
rm -rf ./lockd/opt/colemancda/swift/*
cp -rf ./usr ./lockd/opt/colemancda/swift/
rm -rf ./usr
