#!/bin/bash
set -e

echo "=> Loading resident SSH keys from YubiKey and saving to ~/.ssh..."
echo "=> Run this script when you want to use your YubiKey on a new computer."
echo "Note: You may be prompted to enter your YubiKey PIN."
echo "----------------------------------------------------------------"
read -p "Press Enter to continue..."

# The -K option loads any resident keys from a FIDO2 device.
# This will generate id_ed25519_sk and id_ed25519_sk.pub in your ~/.ssh directory.
ssh-keygen -K

echo
echo "=> Done."
echo "=> Key handles have been created in ~/.ssh."
echo "You can now add the key to your SSH agent with the following command:"
echo "ssh-add ~/.ssh/id_ed25519_sk"
