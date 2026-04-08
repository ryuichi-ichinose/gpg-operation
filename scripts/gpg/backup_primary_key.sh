#!/bin/bash
set -e

# Check environment variables
: "${GPG_FPR:?Error: GPG_FPR (fingerprint) is not set.}"
: "${GPG_RAMDISK_DIR:?Error: GPG_RAMDISK_DIR is not set.}"

export GNUPGHOME="$GPG_RAMDISK_DIR"

# Check arguments: Target USB is required
TARGET_USB="${1:-}"
if [ -z "$TARGET_USB" ]; then
    echo "Error: Please specify the backup USB mount point as an argument."
    echo "Usage: $0 /path/to/new/usb"
    exit 1
fi

if [ ! -d "$TARGET_USB" ]; then
    echo "Error: Directory '$TARGET_USB' not found."
    exit 1
fi

BACKUP_DIR="${TARGET_USB}/gpg_backup"
mkdir -p "$BACKUP_DIR"

echo "=> Verifying primary key exists in the working directory..."
# Verify that the sec (Secret Key) record exists and is not a stub
if ! gpg --list-secret-keys --with-colons "$GPG_FPR" | awk -F: '$1=="sec" {print $0}' | grep -q ""; then
    echo "Error: The primary secret key is not found in this environment, or the fingerprint is incorrect."
    exit 1
fi

echo "=> Exporting primary key (public and secret) to ${TARGET_USB}..."
gpg --armor --export "$GPG_FPR" > "$BACKUP_DIR/public.asc"
gpg --armor --export-secret-keys "$GPG_FPR!" > "$BACKUP_DIR/primary_secret.asc"

echo "=> Creating QR code for the primary secret key..."
# Note: uses paperkey to create a raw, base64 encoded QR code for ultimate recovery
gpg --export-secret-keys "$GPG_FPR!" | paperkey --output-type raw | base64 | qrencode -o "$BACKUP_DIR/primary-secret-qr.png"

echo "=> Backing up revocation certificate..."
# The revocation certificate is generated automatically by GPG 2.1.17+
cp "$GNUPGHOME/openpgp-revocs.d/${GPG_FPR}.rev" "$BACKUP_DIR/revoke.asc"

sync
echo "=> Primary key backup to new USB ($BACKUP_DIR) complete."