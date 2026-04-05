#!/bin/bash
set -e

: "${GPG_FPR:?エラー: GPG_FPR が未設定だ。}"
: "${GPG_RAMDISK_DIR:?エラー: GPG_RAMDISK_DIR が未設定だ。}"

TARGET_USB="${1:-}"
if [ -z "$TARGET_USB" ] || [ ! -d "$TARGET_USB" ]; then
    echo "エラー: マスター鍵が入っているUSBマウントポイントを指定しろ。"
    exit 1
fi

export GNUPGHOME="$GPG_RAMDISK_DIR"
BACKUP_DIR="${TARGET_USB}/gpg_backup"

# 1. マスター鍵のインポート（期限更新には主鍵の秘密鍵が必須）
echo "=> マスター鍵をインポート中..."
gpg --import "$BACKUP_DIR/primary_secret.asc"
gpg --import "$BACKUP_DIR/subkeys_secret.asc"

echo "=> 有効期限を 1年(1y) 延長します..."
echo "※ GUIでマスター鍵のパスワードを求められるぞ。"

# 2. Expectによる自動更新
# 主鍵(0)、副鍵1(key 1)、副鍵2(key 2)を順番に expire コマンドで更新する
expect <<EOF
set timeout -1
spawn gpg --edit-key $GPG_FPR

expect "gpg>"
# --- 主鍵の期限更新 ---
send "expire\r"
expect "Key is valid for?"
send "1y\r"
expect "Is this correct? (y/N)"
send "y\r"

# --- 副鍵1の期限更新 ---
expect "gpg>"
send "key 1\r"
expect "gpg>"
send "expire\r"
expect "Key is valid for?"
send "1y\r"
expect "Is this correct? (y/N)"
send "y\r"

# --- 副鍵2の期限更新 ---
expect "gpg>"
send "key 2\r"
expect "gpg>"
send "expire\r"
expect "Key is valid for?"
send "1y\r"
expect "Is this correct? (y/N)"
send "y\r"

expect "gpg>"
send "save\r"
expect eof
EOF

# 3. 更新された鍵をUSBに書き戻す
echo "=> 更新された鍵を USB に上書きエクスポート中..."
gpg --armor --export "$GPG_FPR" > "$BACKUP_DIR/public.asc"
gpg --armor --export-secret-keys "$GPG_FPR" > "$BACKUP_DIR/primary_secret.asc"
gpg --armor --export-secret-subkeys "$GPG_FPR" > "$BACKUP_DIR/subkeys_secret.asc"

sync
echo "------------------------------------------------"
echo "✅ 更新完了。新しい有効期限を確認しろ:"
gpg --list-keys "$GPG_FPR"
echo "------------------------------------------------"
echo "※ 注意: ホストPCにも 'make import-keys-to-host' で新しい公開鍵を反映させるのを忘れるな。"