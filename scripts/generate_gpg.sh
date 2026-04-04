#!/bin/bash
set -e

# 環境変数が設定されているかチェックし、なければエラーを吐いて即死する
: "${GPG_KEY_NAME:?エラー: 環境変数 GPG_KEY_NAME が設定されていない。}"
: "${GPG_KEY_EMAIL:?エラー: 環境変数 GPG_KEY_EMAIL が設定されていない。}"
: "${GPG_USB_MOUNT:?エラー: 環境変数 GPG_USB_MOUNT が設定されていない。}"

# BACKUP_DIRは明示的に指定がなければデフォルト値を使う
BACKUP_DIR="${GPG_BACKUP_DIR:-$GPG_USB_MOUNT/gpg_backup}"

echo "設定確認:"
echo "  名前: $GPG_KEY_NAME"
echo "  Email: $GPG_KEY_EMAIL"
echo "  出力先: $BACKUP_DIR"
echo "----------------------------------------"

echo "=> GPG主鍵(Certify)の生成..."
gpg --quick-generate-key "$GPG_KEY_NAME <$GPG_KEY_EMAIL>" ed25519 cert never

# 生成された鍵のフィンガープリントを取得
FPR=$(gpg --list-options show-only-fpr-mbox --list-secret-keys "$GPG_KEY_EMAIL" | awk '{print $1}')
if [ -z "$FPR" ]; then
    echo "鍵の取得に失敗した。スクリプトを終了する。"
    exit 1
fi
echo "フィンガープリント: $FPR"

echo "=> 副鍵(Sign, Encrypt)の生成..."
gpg --quick-add-key "$FPR" ed25519 sign 1y
gpg --quick-add-key "$FPR" cv25519 encr 1y

mkdir -p "$BACKUP_DIR"

echo "=> 失効証明書(Revocation Certificate)の生成..."
gpg --output "$BACKUP_DIR/revoke.asc" --gen-revoke "$FPR"

echo "=> 公開鍵・秘密鍵のエクスポート..."
gpg --armor --export "$FPR" > "$BACKUP_DIR/public.asc"
gpg --armor --export-secret-keys "$FPR" > "$BACKUP_DIR/secret.asc"
gpg --armor --export-secret-subkeys "$FPR" > "$BACKUP_DIR/subkeys.asc"

echo "=> 秘密鍵のQRコード化 (paperkey & qrencode)..."
gpg --export-secret-keys "$FPR" | paperkey --secret-key - --output-type raw | base64 | qrencode -o "$BACKUP_DIR/secret-key-qr.png"

echo "=> GNUPGHOME自体のバックアップ..."
tar -czvf "$BACKUP_DIR/gnupg_dir_backup.tar.gz" -C "$HOME" .gnupg

echo "=> 完了だ。USB($BACKUP_DIR)を確認しろ。"
sync