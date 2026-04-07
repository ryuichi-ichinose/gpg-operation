#!/bin/bash
set -e

# Check environment variables
: "${GPG_FPR:?Error: GPG_FPR is not set.}"
: "${GPG_RAMDISK_DIR:?Error: GPG_RAMDISK_DIR is not set.}"

# Argument check
SOURCE_USB="${1:-}"
QR_DATA="${2:-}"

if [ -z "$SOURCE_USB" ] || [ ! -d "$SOURCE_USB" ]; then
    echo "Error: Please specify the USB mount point as the first argument."
    exit 1
fi

if [ -z "$QR_DATA" ]; then
    echo -n "Please enter the string from the QR code: "
    read -r QR_DATA
fi

BACKUP_DIR="${SOURCE_USB}/gpg_backup"
if [ ! -d "$BACKUP_DIR" ]; then
    echo "Error: Backup directory $BACKUP_DIR not found."
    exit 1
fi

# Set GNUPGHOME
export GNUPGHOME="$GPG_RAMDISK_DIR"
mkdir -p -m 700 "$GNUPGHOME"

# TODO: The following configuration is specific to Fedora-based systems.
# On other distributions (like Debian/Ubuntu), the path to `scdaemon-program` may differ.
# === Fedora Optimized Configuration ===
cat <<EOF > "$GNUPGHOME/scdaemon.conf"
disable-ccid
pcsc-shared
EOF
cat <<EOF > "$GNUPGHOME/gpg-agent.conf"
scdaemon-program /usr/libexec/scdaemon
EOF

# === Restoration Process ===
echo "=> Converting public key and decoding QR data..."
gpg --dearmor < "$BACKUP_DIR/public.asc" > "$GNUPGHOME/public.gpg"
echo "$QR_DATA" | base64 -d > "$GNUPGHOME/secret_fragment.bin"

echo "=> Reconstructing secret key with paperkey..."
paperkey --pubring "$GNUPGHOME/public.gpg" \
         --secrets "$GNUPGHOME/secret_fragment.bin" \
         --output "$GNUPGHOME/restored_private.gpg"

echo "=> Importing restored secret key..."
gpg --import "$GNUPGHOME/restored_private.gpg"

# Set trust level to Ultimate
echo -e "5\ny\n" | gpg --command-fd 0 --edit-key "$GPG_FPR" trust

# === Write Back to USB Section ===
echo "=> Backing up restored primary key to USB ($BACKUP_DIR/primary_secret.asc)..."

# If an existing file is found, create a backup
if [ -f "$BACKUP_DIR/primary_secret.asc" ]; then
    mv "$BACKUP_DIR/primary_secret.asc" "$BACKUP_DIR/primary_secret.asc.bak"
    echo "   (Backed up existing primary_secret.asc to .bak)"
fi

# Export the secret key in ASCII Armor format
gpg --export-secret-keys --armor "$GPG_FPR" > "$BACKUP_DIR/primary_secret.asc"

echo "=> Write-back to USB complete."

# Shred temporary binary files
shred -u "$GNUPGHOME/public.gpg" "$GNUPGHOME/secret_fragment.bin" "$GNUPGHOME/restored_private.gpg"

echo "--------------------------------------------------"
echo "=> All steps complete. The secret key on the USB has been restored and updated."
gpg -K "$GPG_FPR"