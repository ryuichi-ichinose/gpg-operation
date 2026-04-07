#!/bin/bash
: "${GPG_RAMDISK_DIR:?Error: GPG_RAMDISK_DIR is not set.}"

if [ -d "$GPG_RAMDISK_DIR" ]; then
    # Use shred to securely wipe the files before removing them
    find "$GPG_RAMDISK_DIR" -type f -exec shred -u -n 3 {} +
    rm -rf "$GPG_RAMDISK_DIR"
    echo "=> Temporary directory ($GPG_RAMDISK_DIR) has been securely wiped."
else
    echo "=> Temporary directory not found, no cleanup needed."
fi