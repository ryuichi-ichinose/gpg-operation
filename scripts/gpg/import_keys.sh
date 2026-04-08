#!/bin/bash
set -e

: "${GPG_FPR:?Error: GPG_FPR is not set.}"
: "${GPG_RAMDISK_DIR:?Error: GPG_RAMDISK_DIR is not set.}"

SOURCE_USB="${1:-}"
if [ -z "$SOURCE_USB" ] || [ ! -d "$SOURCE_USB" ]; then
    echo "Error: Please specify the source USB mount point as an argument."
    echo "Usage: $0 /path/to/usb"
    exit 1
fi

BACKUP_DIR="${SOURCE_USB}/gpg_backup"
if [ ! -d "$BACKUP_DIR" ]; then
    echo "Error: Backup directory $BACKUP_DIR not found."
    exit 1
fi

export GNUPGHOME="$GPG_RAMDISK_DIR"

# === Setup Environment ===
# Create the directory before writing files to it (safe if it already exists)
mkdir -p -m 700 "$GNUPGHOME"

# === scdaemon configuration to avoid conflicts (use pcscd) ===
# --- Optimized settings for Fedora (GUI compatible) ---
cat <<EOF > "$GNUPGHOME/scdaemon.conf"
disable-ccid
pcsc-shared
EOF

cat <<EOF > "$GNUPGHOME/gpg-agent.conf"
scdaemon-program "$GPG_SCDAEMON_PATH"
EOF
echo "=> Applied GPG agent configuration (scdaemon: $GPG_SCDAEMON_PATH)."

# === Import Keys ===
echo "=> Importing keys..."
gpg --import "$BACKUP_DIR/public.asc"

if [ -f "$BACKUP_DIR/primary_secret.asc" ]; then
    gpg --import "$BACKUP_DIR/primary_secret.asc"
fi

if [ -f "$BACKUP_DIR/subkeys_secret.asc" ]; then
    gpg --import "$BACKUP_DIR/subkeys_secret.asc"
fi

# === Set Trust Level ===
echo "=> Setting key trust level to Ultimate..."
echo -e "5\ny\n" | gpg --command-fd 0 --edit-key "$GPG_FPR" trust

echo "=> Import complete."_DIR/primary_secret.asc"
fi

if [ -f "$BACKUP_DIR/subkeys_secret.asc" ]; then
    gpg --import "$BACKUP_DIR/subkeys_secret.asc"
fi

# === Set Trust Level ===
echo "=> Setting key trust level to Ultimate..."
echo -e "5\ny\n" | gpg --command-fd 0 --edit-key "$GPG_FPR" trust

echo "=> Import complete."