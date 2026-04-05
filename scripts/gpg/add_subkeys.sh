#!/bin/bash
set -e

: "${GPG_FPR:?エラー: GPG_FPR が未設定だ。}"
: "${GPG_RAMDISK_DIR:?エラー: GPG_RAMDISK_DIR が未設定だ。}"

TARGET_USB="${1:-}"
if [ -z "$TARGET_USB" ] || [ ! -d "$TARGET_USB" ]; then
    echo "エラー: バックアップ先のUSBマウントポイントを正しく指定しろ。"
    echo "使い方: $0 /mnt/usb_master"
    exit 1
fi

export GNUPGHOME="$GPG_RAMDISK_DIR"

echo "=> 副鍵(Sign, Encrypt)の生成..."
gpg --quick-add-key "$GPG_FPR" ed25519 sign 1y
gpg --quick-add-key "$GPG_FPR" cv25519 encr 1y

BACKUP_DIR="${TARGET_USB}/gpg_backup"
mkdir -p "$BACKUP_DIR"

echo "=> ${TARGET_USB} へ副鍵をエクスポート中..."
gpg --armor --export-secret-subkeys "$GPG_FPR" > "$BACKUP_DIR/subkeys_secret.asc"

# --- 根本解決の追加箇所 ---
echo "=> 最新の公開鍵(副鍵含む)を上書きエクスポート中..."
gpg --armor --export "$GPG_FPR" > "$BACKUP_DIR/public.asc"
# --------------------------

sync
echo "=> 単一USBへの副鍵エクスポートと、公開鍵のアップデートが完了した。"