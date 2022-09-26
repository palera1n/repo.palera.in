#!/bin/bash
GPG_KEY="69C4B31BED834452F3BC21F8FB45AF9E072306ED"
OUTPUT_DIR="publish"

script_full_path=$(dirname "$0")
cd "$script_full_path" || exit 1
# rm $OUTPUT_DIR/Packages* $OUTPUT_DIR/*Release*
rm -rf $OUTPUT_DIR
mkdir -p $OUTPUT_DIR

echo "[Repository] Generating Packages..."
apt-ftparchive packages ./pool > $OUTPUT_DIR/Packages
zstd -q -c19 $OUTPUT_DIR/Packages > $OUTPUT_DIR/Packages.zst
xz -c9 $OUTPUT_DIR/Packages > $OUTPUT_DIR/Packages.xz
bzip2 -c9 $OUTPUT_DIR/Packages > $OUTPUT_DIR/Packages.bz2
gzip -nc9 $OUTPUT_DIR/Packages > $OUTPUT_DIR/Packages.gz
lzma -c9 $OUTPUT_DIR/Packages > $OUTPUT_DIR/Packages.lzma
lz4 -c9 $OUTPUT_DIR/Packages > $OUTPUT_DIR/Packages.lz4

echo "[Repository] Generating Release..."
apt-ftparchive \
    -o APT::FTPArchive::Release::Origin="palera1n" \
    -o APT::FTPArchive::Release::Label="palera1n" \
    -o APT::FTPArchive::Release::Suite="stable" \
    -o APT::FTPArchive::Release::Version="1.0" \
    -o APT::FTPArchive::Release::Codename="palera1n-repo" \
    -o APT::FTPArchive::Release::Architectures="iphoneos-arm64" \
    -o APT::FTPArchive::Release::Components="main" \
    -o APT::FTPArchive::Release::Description="palera1n's official repo." \
    release $OUTPUT_DIR > $OUTPUT_DIR/Release

echo "[Repository] Signing Release using GPG Key..."
gpg -vabs -u $GPG_KEY -o $OUTPUT_DIR/Release.gpg $OUTPUT_DIR/Release
echo "[Repository] Generated detached signature for Release"
gpg --clearsign -u $GPG_KEY -o $OUTPUT_DIR/InRelease $OUTPUT_DIR/Release
echo "[Repository] Generated in-line signature for Release"

cp -R pool "$OUTPUT_DIR"
cp CydiaIcon.png "$OUTPUT_DIR"
cp index.html "$OUTPUT_DIR"
