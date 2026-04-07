#!/bin/bash
set -e

: "${GPG_KEY_NAME:?Error: GPG_KEY_NAME is not set.}"
: "${GPG_KEY_EMAIL:?Error: GPG_KEY_EMAIL is not set.}"
: "${GPG_RAMDISK_DIR:?Error: GPG_RAMDISK_DIR is not set.}"

TARGET_USB="${1:-}"
if [ -z "$TARGET_USB" ] || [ ! -d "$TARGET_USB" ]; then
    echo "Error: Please specify the output USB mount point as an argument."
    echo "Usage: $0 /path/to/usb"
    exit 1
fi

export GNUPGHOME="$GPG_RAMDISK_DIR"
mkdir -p -m 700 "$GNUPGHOME"

BACKUP_DIR="${TARGET_USB}/gpg_backup"
mkdir -p "$BACKUP_DIR"

echo "=> Generating GPG primary key (Certify)..."
gpg --quick-generate-key "$GPG_KEY_NAME <$GPG_KEY_EMAIL>" ed25519 cert never

FPR=$(gpg --list-options show-only-fpr-mbox --list-secret-keys "$GPG_KEY_EMAIL" | awk '{print $1}')
echo "------------------------------------------------------------------"
echo "IMPORTANT: Your new key fingerprint is:"
echo "$FPR"
echo "Set this value for GPG_FPR in your .env file for subsequent steps."
echo "------------------------------------------------------------------"

echo "=> Exporting primary key (public and secret)..."
gpg --armor --export "$FPR" > "$BACKUP_DIR/public.asc"
gpg --armor --export-secret-keys "$FPR" > "$BACKUP_DIR/primary_secret.asc"

echo "=> Creating QR code for the primary secret key..."
gpg --export-secret-keys "$FPR" | paperkey --output-type raw | base64 | qrencode -o "$BACKUP_DIR/primary-secret-qr.png"

echo "=> Backing up revocation certificate..."
cp "$GNUPGHOME/openpgp-revocs.d/${FPR}.rev" "$BACKUP_DIR/revoke.asc"

sync
echo "=> Primary key generation and backup to ${TARGET_USB} complete."