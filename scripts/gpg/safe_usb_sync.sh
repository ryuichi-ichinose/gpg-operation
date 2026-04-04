#!/bin/bash
set -e

SOURCE_DIR="${1:-}"
DEST_DIR="${2:-}"

if [ -z "$SOURCE_DIR" ] || [ -z "$DEST_DIR" ]; then
    echo "エラー: コピー元とコピー先を指定しろ。"
    echo "使い方: ./safe_usb_sync.sh /mnt/usb_master/gpg_backup /mnt/usb_new/gpg_backup"
    exit 1
fi

if [ ! -f "$SOURCE_DIR/subkeys_secret.asc" ]; then
    echo "エラー: コピー元に副鍵のバックアップが存在しない。"
    exit 1
fi

echo "====================================================="
echo "【重要】コピー元 (SOURCE) の副鍵データを検証する:"
echo "====================================================="
# ファイル内の鍵一覧と生成日時を表示する
gpg --show-keys --with-sig-list "$SOURCE_DIR/subkeys_secret.asc"
echo "-----------------------------------------------------"

read -p "このデータが最新のマスターデータで間違いないか？ (y/N): " CONFIRM
if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo "中止した。もう一度USBのラベルとマウント先を確認しろ。"
    exit 1
fi

echo "=> 同期を開始する (rsync)..."
# コピー元のディレクトリの内容を、コピー先へ同期する
# -a: アーカイブモード(権限維持), -v: 詳細表示, --delete: コピー元にないファイルを削除
rsync -av --delete "$SOURCE_DIR/" "$DEST_DIR/"

sync
echo "=> 同期完了。新しいUSBの準備ができた。"