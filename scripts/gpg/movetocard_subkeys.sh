#!/bin/bash
set -e

: "${GPG_FPR:?Error: GPG_FPR is not set.}"
: "${GPG_RAMDISK_DIR:?Error: GPG_RAMDISK_DIR is not set.}"

export GNUPGHOME="$GPG_RAMDISK_DIR"

# GPG Agent Configuration
cat <<EOF > "$GNUPGHOME/scdaemon.conf"
disable-ccid
pcsc-shared
EOF

cat <<EOF > "$GNUPGHOME/gpg-agent.conf"
scdaemon-program "$GPG_SCDAEMON_PATH"
EOF

gpgconf --kill all
sleep 1

# --- WARNING AND GUIDE ---
echo "----------------------------------------------------------------"
echo "【WARNING: IRREVERSIBLE ACTION - MOVING SUBKEYS】"
echo "This script will move your 'Sign' and 'Encrypt' subkeys to the YubiKey."
echo "This action is PERMANENT. Subkeys cannot be moved back from the hardware."
echo ""
echo "A GUI prompt will appear. You will need to enter:"
echo "1. GPG Passphrase: Your key's password"
echo "2. Admin PIN: Your YubiKey's Admin PIN (default: 12345678)"
echo ""
echo "※ Don't forget to physically touch your YubiKey when it flashes."
echo "----------------------------------------------------------------"
read -p "Press Enter to proceed, or Ctrl+C to abort."

echo "=> Moving subkeys to YubiKey (with overwrite support)..."

expect <<EOF
set timeout -1
spawn gpg --expert --edit-key $GPG_FPR

# --- First Subkey (Sign) ---
expect "gpg>"
send "key 1\r"
expect "gpg>"
send "keytocard\r"
expect "Your selection?"
# Slot 1 is for Signature
send "1\r"

# Handle overwrite confirmation if it appears
expect {
    "Replace existing key? (y/N) " {
        send "y\r"
        exp_continue
    }
    "gpg>"
}

# --- Second Subkey (Encrypt) ---
# Deselect key 1, then select key 2
send "key 1\r"
expect "gpg>"
send "key 2\r"
expect "gpg>"
send "keytocard\r"
expect "Your selection?"
# Slot 2 is for Encryption
send "2\r"

# Handle overwrite confirmation for the Encrypt key
expect {
    "Replace existing key? (y/N) " {
        send "y\r"
        exp_continue
    }
    "gpg>"
}

send "save\r"
expect eof
EOF

echo "=> Process complete. Verify that subkeys are now stubs (ssb>)."
gpg --list-secret-keys "$GPG_FPR"

echo "----------------------------------------------------------------"
echo "IMPORTANT: The subkeys have been moved to the YubiKey for daily use."
echo "The original subkey file ('subkeys_secret.asc') still exists on your"
echo "backup USB. This file is a critical backup. Keep your USB backup"
echo "in a physically secure, offline location."
echo "----------------------------------------------------------------"