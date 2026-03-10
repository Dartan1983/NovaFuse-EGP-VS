#!/bin/bash
set -e

VERSION="v0.1.0"
BUNDLE_NAME="NovaFuse-EGP-VS-$VERSION"
OUTDIR="./usb-bundle-$VERSION"

echo "Creating USB bundle: $OUTDIR"

# Clean and prepare output directory
rm -rf "$OUTDIR"
mkdir -p "$OUTDIR"

# Copy core files
cp -r verifier tests cert-schema "$OUTDIR/"
cp README.md ASSESSOR-RUN.md CHANGE_CONTROL.md "$OUTDIR/"

# Copy USB distribution assets
cp RELEASE-HASHES.txt NovaFuse-PublicKey.asc USB-Distribution-Checklist.md USB-Chain-of-Custody.md "$OUTDIR/"

# Generate SHA-256 hashes (excluding signature files)
cd "$OUTDIR"
find . -type f ! -name "RELEASE-HASHES.txt*" -exec sha256sum {} \; | sed 's|^\([a-f0-9]*\)  \./|\\1  |' > RELEASE-HASHES.txt

# Sign the hash manifest
if command -v gpg &> /dev/null; then
    echo "Signing RELEASE-HASHES.txt with GPG..."
    gpg --armor --output RELEASE-HASHES.txt.sig --detach-sign RELEASE-HASHES.txt
    echo "✅ Created: RELEASE-HASHES.txt.sig"
else
    echo "⚠️  GPG not found. Skipping signature generation."
fi

echo "✅ USB bundle created at: $OUTDIR"
echo "📦 Bundle contents:"
ls -la "$OUTDIR"
