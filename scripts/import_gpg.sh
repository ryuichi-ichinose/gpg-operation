#!/bin/bash
set -e

USB_MOUNT="/mnt/usb"
BACKUP_DIR="$USB_MOUNT/gpg_backup"

if [ ! -d "$BACKUP_DIR" ]; then
    echo "USBにバックアップが見つからないぞ。"
    exit 1
fi

echo "=> USBから公開鍵と秘密鍵をインポート..."
gpg --import "$BACKUP_DIR/public.asc"
gpg --import "$BACKUP_DIR/secret.asc"

# インポートした鍵を信用する（Ultimate）
FPR=$(gpg --list-options show-only-fpr-mbox --list-secret-keys | awk 'NR==1 {print $1}')
echo -e "5\ny\n" | gpg --command-fd 0 --edit-key "$FPR" trust