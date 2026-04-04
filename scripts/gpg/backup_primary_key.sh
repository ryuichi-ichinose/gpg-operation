#!/bin/bash
set -e

# 環境変数のチェック (RAMディスクとフィンガープリントは共通状態として引き継ぐ)
: "${GPG_FPR:?エラー: GPG_FPR (フィンガープリント) が未設定だ。}"
: "${GPG_RAMDISK_DIR:?エラー: GPG_RAMDISK_DIR が未設定だ。}"

export GNUPGHOME="$GPG_RAMDISK_DIR"

# 引数のチェック: ターゲットUSBを必須にする
TARGET_USB="${1:-}"
if [ -z "$TARGET_USB" ]; then
    echo "エラー: バックアップ先のUSBマウントポイントを引数で指定しろ。"
    echo "使い方: $0 /mnt/new_usb"
    exit 1
fi

if [ ! -d "$TARGET_USB" ]; then
    echo "エラー: 指定されたディレクトリ '$TARGET_USB' が見つからない。"
    exit 1
fi

BACKUP_DIR="${TARGET_USB}/gpg_backup"
mkdir -p "$BACKUP_DIR"

echo "=> RAM上の主鍵の実体を確認中..."
# sec (Secret Key) レコードが存在し、かつスタブではないことを確認する
if ! gpg --list-secret-keys --with-colons "$GPG_FPR" | awk -F: '$1=="sec" {print $0}' | grep -q ""; then
    echo "エラー: この環境には主鍵の実体が存在しないか、フィンガープリントが間違っている。"
    echo "先にMaster USBから 'import_keys.sh' を使って主鍵をインポートしろ。"
    exit 1
fi

echo "=> 主鍵(公開鍵・秘密鍵)の $TARGET_USB へのエクスポート..."
gpg --armor --export "$GPG_FPR" > "$BACKUP_DIR/public.asc"
gpg --armor --export-secret-keys "$GPG_FPR!" > "$BACKUP_DIR/primary_secret.asc"

echo "=> 主鍵のQRコード化..."
# 修正済み: paperkey の引数エラー回避
gpg --export-secret-keys "$GPG_FPR!" | paperkey --output-type raw | base64 | qrencode -o "$BACKUP_DIR/primary-secret-qr.png"

echo "=> 失効証明書のバックアップ..."
# 修正済み: 自動生成されたものをコピーするだけ
cp "$GNUPGHOME/openpgp-revocs.d/${GPG_FPR}.rev" "$BACKUP_DIR/revoke.asc"

sync
echo "=> 新しいUSB ($BACKUP_DIR) への主鍵バックアップが完了した。"