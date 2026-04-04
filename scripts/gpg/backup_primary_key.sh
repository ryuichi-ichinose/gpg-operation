
#!/bin/bash
set -e

: "${GPG_FPR:?エラー: GPG_FPR (フィンガープリント) が未設定だ。}"
: "${GPG_USB_MOUNT:?エラー: GPG_USB_MOUNT が未設定だ。}"

BACKUP_DIR="${GPG_USB_MOUNT}/gpg_backup"
mkdir -p "$BACKUP_DIR"

echo "=> RAM上の主鍵の実体を確認中..."
# sec (Secret Key) レコードが存在し、かつスタブではないことを確認する
if ! gpg --list-secret-keys --with-colons "$GPG_FPR" | awk -F: '$1=="sec" {print $0}' | grep -q ""; then
    echo "エラー: この環境には主鍵の実体が存在しないか、フィンガープリントが間違っている。"
    echo "先にMaster USBから 'import_keys.sh' を使って主鍵をインポートしろ。"
    exit 1
fi

echo "=> 主鍵(公開鍵・秘密鍵)の新しいUSBへのエクスポート..."
gpg --armor --export "$GPG_FPR" > "$BACKUP_DIR/public.asc"
# ! を付けることで、副鍵を含まず主鍵のみを明示的にエクスポートする
gpg --armor --export-secret-keys "$GPG_FPR!" > "$BACKUP_DIR/primary_secret.asc"

echo "=> 主鍵のQRコード化..."
gpg --export-secret-keys "$GPG_FPR!" | paperkey --secret-key - --output-type raw | base64 | qrencode -o "$BACKUP_DIR/primary-secret-qr.png"

echo "=> 失効証明書(Revocation Certificate)の生成..."
gpg --output "$BACKUP_DIR/revoke.asc" --gen-revoke "$GPG_FPR"

sync
echo "=> 新しいUSB ($BACKUP_DIR) への主鍵バックアップが完了した。"