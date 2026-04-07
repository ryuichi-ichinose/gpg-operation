#!/bin/bash
set -e

# Check environment variables (identity is maintained as global state)
: "${SSH_KEY_EMAIL:?Error: Environment variable SSH_KEY_EMAIL is not set.}"

# Get target USB from the first argument
TARGET_USB="${1:-}"

if [ -z "$TARGET_USB" ]; then
    echo "Error: Please specify the backup USB mount point as an argument."
    echo "Usage: $0 /path/to/usb"
    exit 1
fi

if [ ! -d "$TARGET_USB" ]; then
    echo "Error: Directory '$TARGET_USB' not found."
    exit 1
fi

BACKUP_DIR="${TARGET_USB}/ssh_backup"
mkdir -p "$BACKUP_DIR"

echo "Configuration Check (FIDO2 SSH):"
echo "  Email (Comment): $SSH_KEY_EMAIL"
echo "  Target USB: $TARGET_USB"
echo "  Output Directory: $BACKUP_DIR"
echo "----------------------------------------"
read -p "Press Enter to begin key generation..."

# The 'resident' option makes the key material reside on the YubiKey itself.
# This allows the key to be loaded on a new PC instantly with ssh-keygen -K.
echo "=> Generating ed25519-sk SSH key on the YubiKey..."
echo "Note: Touch the YubiKey when it flashes. You will also be prompted for your PIN."

# ssh-keygen will prompt for confirmation if the output file already exists.
ssh-keygen -t ed25519-sk -O resident -C "$SSH_KEY_EMAIL" -f "$BACKUP_DIR/id_ed25519_sk"

echo "=> Generation complete."

# Adjust permissions for the key handle and public key
chmod 600 "$BACKUP_DIR/id_ed25519_sk"
chmod 644 "$BACKUP_DIR/id_ed25519_sk.pub"

echo "----------------------------------------"
echo "Register the following public key in your server's ~/.ssh/authorized_keys file:"
cat "$BACKUP_DIR/id_ed25519_sk.pub"
echo "----------------------------------------"

sync
echo "=> All operations complete."