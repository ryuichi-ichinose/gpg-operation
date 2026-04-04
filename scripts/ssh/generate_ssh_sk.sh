#!/bin/bash
set -e

# 環境変数のチェック
: "${SSH_KEY_EMAIL:?エラー: 環境変数 SSH_KEY_EMAIL が設定されていない。}"
: "${SSH_USB_MOUNT:?エラー: 環境変数 SSH_USB_MOUNT が設定されていない。}"

BACKUP_DIR="${SSH_BACKUP_DIR:-$SSH_USB_MOUNT/ssh_backup}"

echo "設定確認 (FIDO2 SSH):"
echo "  Email (Comment): $SSH_KEY_EMAIL"
echo "  出力先: $BACKUP_DIR"
echo "----------------------------------------"

mkdir -p "$BACKUP_DIR"

# residentオプションを付けることで、YubiKey自体に秘密鍵（と公開鍵のペア）を常駐させる
# これにより、新しいPCに移動しても ssh-add -K で即座に鍵を復元できる
echo "=> YubiKey内で ed25519-sk SSH鍵を生成する..."
echo "注意: YubiKeyが点滅したらタッチしろ。PINの入力も求められる。"

ssh-keygen -t ed25519-sk -O resident -C "$SSH_KEY_EMAIL" -f "$BACKUP_DIR/id_ed25519_sk"

echo "=> 生成完了。"
echo "=> $BACKUP_DIR を確認しろ。"

# キーハンドルと公開鍵のパーミッション調整（USBがext4などの場合）
chmod 600 "$BACKUP_DIR/id_ed25519_sk"
chmod 644 "$BACKUP_DIR/id_ed25519_sk.pub"

echo "以下の公開鍵をサーバーの ~/.ssh/authorized_keys に登録しろ："
cat "$BACKUP_DIR/id_ed25519_sk.pub"

sync