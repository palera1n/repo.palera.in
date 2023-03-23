#!/bin/bash
GPG_KEY="FB04F6C8EC56DA32F33008C53D1B28A5FACCB53B"
OUTPUT_DIR="publish"

script_full_path=$(dirname "$0")
cd "$script_full_path" || exit 1
rm -rf $OUTPUT_DIR
mkdir -p $OUTPUT_DIR/{rootful,rootless}

dirs=(./pool ./pool/iphoneos-arm ./pool/iphoneos-arm64)

set_arch_vars() {
    case $(basename "$1") in
        pool)
            output_dir=$OUTPUT_DIR
            extra=(extra_packages*)
            ;;
        iphoneos-arm)
            output_dir=$OUTPUT_DIR/rootful
            extra=(extra_packages_rootful)
            ;;
        iphoneos-arm64)
            output_dir=$OUTPUT_DIR/rootless
            extra=(extra_packages_rootless)
            ;;
    esac
}


echo "[*] Generating Packages..."
for d in "${dirs[@]}"; do
    set_arch_vars "$d"
    apt-ftparchive packages "$d" > $output_dir/Packages
    echo >> $output_dir/Packages
    cat "${extra[@]}" >> $output_dir/Packages 2>/dev/null
    zstd -q -c19 $output_dir/Packages > $output_dir/Packages.zst
    xz -c9 $output_dir/Packages > $output_dir/Packages.xz
    bzip2 -c9 $output_dir/Packages > $output_dir/Packages.bz2
    gzip -nc9 $output_dir/Packages > $output_dir/Packages.gz
    lzma -c9 $output_dir/Packages > $output_dir/Packages.lzma
    lz4 -c9 $output_dir/Packages > $output_dir/Packages.lz4
done

echo "[*] Generating Release..."
for d in "${dirs[@]}"; do
    set_arch_vars "$d"
    apt-ftparchive \
        -o APT::FTPArchive::Release::Origin="palera1n" \
        -o APT::FTPArchive::Release::Label="palera1n" \
        -o APT::FTPArchive::Release::Suite="stable" \
        -o APT::FTPArchive::Release::Version="1.0" \
        -o APT::FTPArchive::Release::Codename="palera1n-repo" \
        -o APT::FTPArchive::Release::Architectures="iphoneos-arm iphoneos-arm64" \
        -o APT::FTPArchive::Release::Components="main" \
        -o APT::FTPArchive::Release::Description="palera1n's official repo" \
        release $output_dir > $output_dir/Release
done

echo "[*] Signing Release using GPG Key..."
for d in "${dirs[@]}"; do
    set_arch_vars "$d"
    gpg -abs -u $GPG_KEY -o $output_dir/Release.gpg $output_dir/Release
    gpg -abs -u $GPG_KEY --clearsign -o $output_dir/InRelease $output_dir/Release
done

echo "[*] Copying files..."
cp -R pool "$OUTPUT_DIR"
cp *.png "$OUTPUT_DIR"
#cp index.html "$OUTPUT_DIR"

echo "[*] Done!"
