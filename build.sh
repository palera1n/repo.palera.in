#!/bin/bash
GPG_KEY="FB04F6C8EC56DA32F33008C53D1B28A5FACCB53B"
OUTPUT_DIR="publish"

script_full_path=$(dirname "$0")
cd "$script_full_path" || exit 1
rm -rf $OUTPUT_DIR
mkdir -p $OUTPUT_DIR

echo "[*] Generating Packages..."
apt-ftparchive packages ./pool > $OUTPUT_DIR/Packages
zstd -q -c19 $OUTPUT_DIR/Packages > $OUTPUT_DIR/Packages.zst
xz -c9 $OUTPUT_DIR/Packages > $OUTPUT_DIR/Packages.xz
bzip2 -c9 $OUTPUT_DIR/Packages > $OUTPUT_DIR/Packages.bz2
gzip -nc9 $OUTPUT_DIR/Packages > $OUTPUT_DIR/Packages.gz
lzma -c9 $OUTPUT_DIR/Packages > $OUTPUT_DIR/Packages.lzma
lz4 -c9 $OUTPUT_DIR/Packages > $OUTPUT_DIR/Packages.lz4

echo "[*] Generating Release..."
apt-ftparchive \
    -o APT::FTPArchive::Release::Origin="palera1n" \
    -o APT::FTPArchive::Release::Label="palera1n" \
    -o APT::FTPArchive::Release::Suite="stable" \
    -o APT::FTPArchive::Release::Version="1.0" \
    -o APT::FTPArchive::Release::Codename="palera1n-repo" \
    -o APT::FTPArchive::Release::Architectures="iphoneos-arm64" \
    -o APT::FTPArchive::Release::Components="main" \
    -o APT::FTPArchive::Release::Description="palera1n's official repo" \
    release $OUTPUT_DIR > $OUTPUT_DIR/Release

echo "[*] Signing Release using GPG Key..."
gpg -abs -u $GPG_KEY -o $OUTPUT_DIR/Release.gpg $OUTPUT_DIR/Release
gpg -abs -u $GPG_KEY --clearsign -o $OUTPUT_DIR/InRelease $OUTPUT_DIR/Release

echo "[*] Copying files..."
cp -R pool "$OUTPUT_DIR"
cp *.png "$OUTPUT_DIR"
cp index.html "$OUTPUT_DIR"

echo "[*] Done!"
