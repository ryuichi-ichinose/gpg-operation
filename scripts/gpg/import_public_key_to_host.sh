#!/bin/bash
set -e

# 第一引数からターゲットUSBを取得
TARGET_USB="${1:-}"

if [ -z "$TARGET_USB" ]; then
    echo "エラー: 公開鍵が保存されているUSBマウントポイントを指定しろ。"
    echo "使い方: $0 /run/media/ichinose/STORE\ N\ GO"
    exit 1
fi

# 公開鍵のパス（これまでのスクリプトの出力先に合わせる）
PUBKEY_FILE="${TARGET_USB}/gpg_backup/public.asc"

if [ ! -f "$PUBKEY_FILE" ]; then
    echo "エラー: 公開鍵ファイル '$PUBKEY_FILE' が見つからない。"
    exit 1
fi

echo "=> メイン環境に公開鍵をインポート中..."
# ここでは GNUPGHOME を指定せず、デフォルトの ~/.gnupg に入れる
gpg --import "$PUBKEY_FILE"

# フィンガープリントを抽出
FPR=$(gpg --with-colons --import-options show-only --import "$PUBKEY_FILE" | awk -F: '$1=="fpr"{print $10;exit}')

echo "=> 鍵の信用度(Trust)を Ultimate に設定中..."
echo -e "5\ny\n" | gpg --command-fd 0 --edit-key "$FPR" trust

echo "=> YubiKey との紐付けを確立中..."
# これを叩くことで、GPGが「この公開鍵の秘密鍵はカード内にある」と認識（スタブ化）する
gpg --card-status > /dev/null

echo "------------------------------------------------"
echo "完了。現在の鍵の状態を確認しろ:"
gpg --list-secret-keys --keyid-format LONG
echo "------------------------------------------------"
echo "ssb> や sec> のように '>' が付いていれば、紐付け成功だ。"