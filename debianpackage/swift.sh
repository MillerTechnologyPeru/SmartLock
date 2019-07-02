# Set Swift Path
export PATH=/opt/colemancda/swift/usr/bin:"${PATH}"

# Install Swift
echo "Extracting Swift"
tar xvf swift.tar
echo "Installing Swift"
rm -rf /opt/colemancda/swift/*
cp -rf ./usr /opt/colemancda/swift/
echo "Copying Swift to package"
rm -rf ./lockd/opt/colemancda/swift/*
cp -rf ./usr ./lockd/opt/colemancda/swift/
echo "Cleanup extracted files"
rm -rf ./usr
