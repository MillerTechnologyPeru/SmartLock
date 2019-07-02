echo "Building Debian package"
dpkg-deb -b lockd lockd.deb

echo "Creating static repo"
reprepro -b ./repo includedeb stretch ./lockd.deb
