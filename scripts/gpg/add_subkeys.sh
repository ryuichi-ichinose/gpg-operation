#!/bin/bash
set -e

: "${GPG_FPR:?エラー: GPG_FPR が未設定だ。}"
: "${GPG_RAMDISK_DIR:?エラー: GPG_RAMDISK_DIR が未設定だ。}"

if [ "$#" -eq 0 ]; then
    echo "エラー: バックアップ先のUSBマウントポイントを1つ以上指定しろ。"
    echo "使い方: $0 /mnt/usb_master /mnt/usb_replica_1"
    exit 1
fi

export GNUPGHOME="$GPG_RAMDISK_DIR"

echo "=> 副鍵(Sign, Encrypt)の生成..."
gpg --quick-add-key "$GPG_FPR" ed25519 sign 1y
gpg --quick-add-key "$GPG_FPR" cv25519 encr 1y

# 引数として渡されたすべてのパス($@)に対してループ処理を行う
for TARGET_USB in "$@"; do
    if [ ! -d "$TARGET_USB" ]; then
        echo "警告: USBマウントポイント $TARGET_USB が見つからない。スキップする。"
        continue
    fi
    
    BACKUP_DIR="${TARGET_USB}/gpg_backup"
    mkdir -p "$BACKUP_DIR"
    
    echo "=> $TARGET_USB へ副鍵をエクスポート中..."
    gpg --armor --export-secret-subkeys "$GPG_FPR" > "$BACKUP_DIR/subkeys_secret.asc"
done

sync
echo "=> 指定された全USBへの副鍵エクスポート完了。"