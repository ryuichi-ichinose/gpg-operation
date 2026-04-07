#!/bin/bash
set -e

: "${GPG_FPR:?Error: GPG_FPR is not set.}"
: "${GPG_RAMDISK_DIR:?Error: GPG_RAMDISK_DIR is not set.}"

TARGET_USB="${1:-}"
if [ -z "$TARGET_USB" ] || [ ! -d "$TARGET_USB" ]; then
    echo "Error: Please specify a valid mount point for the backup USB."
    echo "Usage: $0 /path/to/usb"
    exit 1
fi

export GNUPGHOME="$GPG_RAMDISK_DIR"

echo "=> Generating subkeys (Sign, Encrypt)..."
gpg --quick-add-key "$GPG_FPR" ed25519 sign 1y
gpg --quick-add-key "$GPG_FPR" cv25519 encr 1y

BACKUP_DIR="${TARGET_USB}/gpg_backup"
mkdir -p "$BACKUP_DIR"

echo "=> Exporting subkeys to ${TARGET_USB}..."
gpg --armor --export-secret-subkeys "$GPG_FPR" > "$BACKUP_DIR/subkeys_secret.asc"

# Overwrite with the latest public key, including the new subkeys
echo "=> Exporting the latest public key..."
gpg --armor --export "$GPG_FPR" > "$BACKUP_DIR/public.asc"

sync
echo "=> Subkey export and public key update to USB complete."