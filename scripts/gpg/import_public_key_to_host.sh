#!/bin/bash
set -e

: "${GPG_FPR:?Error: GPG_FPR is not set.}"

# Get target USB from the first argument
TARGET_USB="${1:-}"

if [ -z "$TARGET_USB" ]; then
    echo "Error: Please specify the USB mount point where the public key is stored."
    echo "Usage: $0 /path/to/usb"
    exit 1
fi

# Path to the public key (matches the output of previous scripts)
PUBKEY_FILE="${TARGET_USB}/gpg_backup/public.asc"

if [ ! -f "$PUBKEY_FILE" ]; then
    echo "Error: Public key file '$PUBKEY_FILE' not found."
    exit 1
fi

echo "=> Importing public key to the main environment..."
# Here we do not set GNUPGHOME, so it imports to the default ~/.gnupg
gpg --import "$PUBKEY_FILE"

echo "=> Setting key trust level to Ultimate..."
echo -e "5\ny\n" | gpg --command-fd 0 --edit-key "$GPG_FPR" trust

echo "=> Establishing link with YubiKey..."
# This command makes GPG recognize that the secret key for this public key is on the card (creates a stub).
gpg --card-status > /dev/null

echo "------------------------------------------------"
echo "Done. Check the current key status:"
gpg --list-secret-keys --keyid-format LONG
echo "------------------------------------------------"
echo "If you see a '>' character (e.g., 'ssb>'), the key is successfully linked to the card."