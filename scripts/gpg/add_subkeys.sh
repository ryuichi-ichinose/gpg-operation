#!/bin/bash
set -e

: "${GPG_FPR:?エラー: GPG_FPR が未設定だ。}"
# 複数のマウントポイントをスペース区切りで受け取る
: "${GPG_USB_MOUNTS:?エラー: GPG_USB_MOUNTS が未設定だ。(例: \"/mnt/usb_master /mnt/usb_rep1 /mnt/usb_rep2\")}"

echo "=> 副鍵(Sign, Encrypt)の生成..."
gpg --quick-add-key "$GPG_FPR" ed25519 sign 1y
gpg --quick-add-key "$GPG_FPR" cv25519 encr 1y

for MOUNT in $GPG_USB_MOUNTS; do
    BACKUP_DIR="${MOUNT}/gpg_backup"
    if [ ! -d "$BACKUP_DIR" ]; then
        echo "警告: $BACKUP_DIR が見つからない。スキップする。"
        continue
    fi
    
    echo "=> $MOUNT へ副鍵をエクスポート中..."
    gpg --armor --export-secret-subkeys "$GPG_FPR" > "$BACKUP_DIR/subkeys_secret.asc"
done

sync
echo "=> 全USBへの副鍵エクスポート完了。"