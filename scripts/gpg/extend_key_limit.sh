#!/bin/bash
set -e

: "${GPG_FPR:?Error: GPG_FPR is not set.}"
: "${GPG_RAMDISK_DIR:?Error: GPG_RAMDISK_DIR is not set.}"

TARGET_USB="${1:-}"
if [ -z "$TARGET_USB" ] || [ ! -d "$TARGET_USB" ]; then
    echo "Error: Please specify the USB mount point containing the master key."
    exit 1
fi

export GNUPGHOME="$GPG_RAMDISK_DIR"
BACKUP_DIR="${TARGET_USB}/gpg_backup"

# 1. Import master key (the primary secret key is required to extend expiration)
echo "=> Importing master key..."
gpg --import "$BACKUP_DIR/primary_secret.asc"
gpg --import "$BACKUP_DIR/subkeys_secret.asc"

# 2. Guide the user
echo "------------------------------------------------------------------"
echo "===> Updating GPG Key Expiration <==="
echo "------------------------------------------------------------------"
echo "Starting an interactive GPG prompt."
echo "Follow the steps below to update the expiration for each key."
echo ""
echo "  1. At the gpg> prompt, type 'list' to see your keys."
echo "  2. To update the primary key, just type 'expire'."
echo "     - Enter the new expiration ('1y', etc.) and confirm ('y')."
echo "  3. To update a subkey, select it with 'key <N>' (e.g., 'key 1')."
echo "     - Ensure the asterisk (*) moves next to the selected key."
echo "     - Then type 'expire' and set the new expiration as before."
echo "  4. Repeat this process for **all keys** (primary and subkeys)."
echo "  5. Finally, type 'save' to apply the changes and exit the prompt."
echo "------------------------------------------------------------------"
echo "Current key status:"
gpg --list-keys "$GPG_FPR"
echo "------------------------------------------------------------------"
read -p "Press Enter when you are ready to start the GPG prompt..."

# 3. Start interactive session
# Explicitly specify the current terminal with --tty
gpg --tty `tty` --edit-key "$GPG_FPR"


# 4. Write the updated keys back to the USB
echo "=> Exporting updated keys back to the USB..."
gpg --armor --export "$GPG_FPR" > "$BACKUP_DIR/public.asc"
gpg --armor --export-secret-keys "$GPG_FPR" > "$BACKUP_DIR/primary_secret.asc"
gpg --armor --export-secret-subkeys "$GPG_FPR" > "$BACKUP_DIR/subkeys_secret.asc"

sync
echo "------------------------------------------------"
echo "Update complete. Verify the new expiration dates:"
gpg --list-keys "$GPG_FPR"
echo "------------------------------------------------"
echo "※ NOTE: Don't forget to run 'make import-keys-to-host' to update your host PC as well."