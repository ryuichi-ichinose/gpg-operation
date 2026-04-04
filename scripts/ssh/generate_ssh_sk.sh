#!/bin/bash
set -e

# 環境変数のチェック (アイデンティティはグローバルな状態として保持)
: "${SSH_KEY_EMAIL:?エラー: 環境変数 SSH_KEY_EMAIL が設定されていない。}"

# 第一引数からターゲットUSBを取得
TARGET_USB="${1:-}"

if [ -z "$TARGET_USB" ]; then
    echo "エラー: バックアップ先のUSBマウントポイントを引数で指定しろ。"
    echo "使い方: $0 /mnt/usb_master"
    exit 1
fi

if [ ! -d "$TARGET_USB" ]; then
    echo "エラー: 指定されたディレクトリ '$TARGET_USB' が見つからない。"
    exit 1
fi

BACKUP_DIR="${TARGET_USB}/ssh_backup"
mkdir -p "$BACKUP_DIR"

echo "設定確認 (FIDO2 SSH):"
echo "  Email (Comment): $SSH_KEY_EMAIL"
echo "  ターゲットUSB: $TARGET_USB"
echo "  出力先: $BACKUP_DIR"
echo "----------------------------------------"

# residentオプションを付けることで、YubiKey自体に秘密鍵（と公開鍵のペア）を常駐させる
# これにより、新しいPCに移動しても ssh-add -K で即座に鍵を復元できる
echo "=> YubiKey内で ed25519-sk SSH鍵を生成する..."
echo "注意: YubiKeyが点滅したらタッチしろ。PINの入力も求められる。"

# 既存のファイルがある場合に上書きするか聞かれるのを防ぐため、あえて上書き確認は残す
ssh-keygen -t ed25519-sk -O resident -C "$SSH_KEY_EMAIL" -f "$BACKUP_DIR/id_ed25519_sk"

echo "=> 生成完了。"

# キーハンドルと公開鍵のパーミッション調整
chmod 600 "$BACKUP_DIR/id_ed25519_sk"
chmod 644 "$BACKUP_DIR/id_ed25519_sk.pub"

echo "----------------------------------------"
echo "以下の公開鍵をサーバーの ~/.ssh/authorized_keys に登録しろ："
cat "$BACKUP_DIR/id_ed25519_sk.pub"

sync
echo "=> すべての処理が完了した。"