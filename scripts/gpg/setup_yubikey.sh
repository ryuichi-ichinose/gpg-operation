#!/bin/bash
set -e

# --- 0. Environment Setup ---
: "${GPG_RAMDISK_DIR:?Error: GPG_RAMDISK_DIR is not set.}"
export GNUPGHOME="$GPG_RAMDISK_DIR"
mkdir -p -m 700 "$GNUPGHOME"

# TODO: The following configuration is specific to Fedora-based systems.
# --- 1. Fedora Optimized Configuration ---
cat <<EOF > "$GNUPGHOME/scdaemon.conf"
disable-ccid
pcsc-shared
EOF

cat <<EOF > "$GNUPGHOME/gpg-agent.conf"
scdaemon-program /usr/libexec/scdaemon
EOF

gpgconf --kill all
sleep 1

# --- WARNING AND GUIDE ---
echo "----------------------------------------------------------------"
echo "【WARNING: YUBIKEY INITIALIZATION】"
echo "This script will change the key attributes on your YubiKey to use ECC."
echo "This should only be done once on a new or reset YubiKey."
echo ""
echo "A GUI prompt may appear asking for your Admin PIN."
echo "The default Admin PIN is: 12345678"
echo "----------------------------------------------------------------"
read -p "Press Enter to proceed, or Ctrl+C to abort."

echo "=> Switching YubiKey to ECC (Ed25519/Curve25519) mode..."

# --- 2. Expect Script (Automated Sequence) ---
expect <<EOF
set timeout 30
spawn gpg --card-edit

expect "gpg/card>"
send "admin\r"

expect "gpg/card>"
send "key-attr\r"

# --- (1) Signature Key ---
# Select algorithm (2: ECC)
expect "Your selection? "
send "2\r"
# Select curve (1: Ed25519)
expect "Your selection? "
send "1\r"

# --- (2) Encryption Key ---
# Select algorithm (2: ECC)
expect "Your selection? "
send "2\r"
# Select curve (1: Curve25519)
expect "Your selection? "
send "1\r"

# --- (3) Authentication Key ---
# Select algorithm (2: ECC)
expect "Your selection? "
send "2\r"
# Select curve (1: Ed25519)
expect "Your selection? "
send "1\r"

# Done
expect "gpg/card>"
send "quit\r"
expect eof
EOF

echo "------------------------------------------------"
echo "Complete. Verify that the key attributes are now ed25519 / cv25519:"
gpg --card-status | grep "Key attributes"
echo "------------------------------------------------"