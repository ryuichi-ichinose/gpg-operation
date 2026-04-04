#!/bin/bash
set -e

: "${GPG_USB_MOUNT:?エラー: GPG_USB_MOUNT が未設定だ。}"
BACKUP_DIR="${GPG_USB_MOUNT}/gpg_backup"

if [ ! -d "$BACKUP_DIR" ]; then
    echo "エラー: バックアップディレクトリが見つからない。"
    exit 1
fi

echo "=> 鍵のインポート..."
gpg --import "$BACKUP_DIR/public.asc"

# 主鍵か副鍵か、存在するものだけインポートする
if [ -f "$BACKUP_DIR/primary_secret.asc" ]; then
    gpg --import "$BACKUP_DIR/primary_secret.asc"
fi

if [ -f "$BACKUP_DIR/subkeys_secret.asc" ]; then
    gpg --import "$BACKUP_DIR/subkeys_secret.asc"
fi

# インポートした鍵をUltimate Trustに設定する
FPR=$(gpg --list-options show-only-fpr-mbox --list-secret-keys | awk 'NR==1 {print $1}')
if [ -n "$FPR" ]; then
    echo -e "5\ny\n" | gpg --command-fd 0 --edit-key "$FPR" trust
    echo "=> 鍵のTrustレベルをUltimateに設定した。"
fi

echo "=> インポート完了。"