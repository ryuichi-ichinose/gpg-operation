#!/bin/bash
set -e

: "${GPG_KEY_NAME:?エラー: GPG_KEY_NAME が未設定だ。}"
: "${GPG_KEY_EMAIL:?エラー: GPG_KEY_EMAIL が未設定だ。}"
: "${GPG_USB_MOUNT:?エラー: GPG_USB_MOUNT が未設定だ。}"

BACKUP_DIR="${GPG_USB_MOUNT}/gpg_backup"
mkdir -p "$BACKUP_DIR"

echo "=> GPG主鍵(Certify)の生成..."
gpg --quick-generate-key "$GPG_KEY_NAME <$GPG_KEY_EMAIL>" ed25519 cert never

FPR=$(gpg --list-options show-only-fpr-mbox --list-secret-keys "$GPG_KEY_EMAIL" | awk '{print $1}')
echo "フィンガープリント: $FPR"

echo "=> 失効証明書のバックアップ..."
# GnuPGが自動生成した失効証明書をコピーするだけでいい
cp "$GNUPGHOME/openpgp-revocs.d/${FPR}.rev" "$BACKUP_DIR/revoke.asc"

echo "=> 主鍵(公開鍵・秘密鍵)のエクスポート..."
gpg --armor --export "$FPR" > "$BACKUP_DIR/public.asc"
gpg --armor --export-secret-keys "$FPR" > "$BACKUP_DIR/primary_secret.asc"

echo "=> 主鍵のQRコード化..."
gpg --export-secret-keys "$FPR" | paperkey --output-type raw | base64 | qrencode -o "$BACKUP_DIR/primary-secret-qr.png"

sync
echo "=> 主鍵の生成とバックアップ完了。"