#!/bin/bash
set -e

echo "=> YubiKeyから常駐SSH鍵(resident keys)を読み込んで ~/.ssh に保存する..."
echo "=> このスクリプトは、新しいPCでYubiKeyを使いたい場合に実行する。"
echo "注意: YubiKeyのPIN入力が求められる場合がある。"

# -KオプションでFIDO2デバイスからresident keyを読み込む
# これにより、id_ed25519_sk と id_ed25519_sk.pub が ~/.ssh/ に生成される
ssh-keygen -K

echo
echo "=> 完了。"
echo "=> ~/.ssh に鍵のハンドルが作成された。"
echo "以下のコマンドでSSHエージェントに鍵を追加して使えるようになる:"
echo "ssh-add ~/.ssh/id_ed25519_sk"
