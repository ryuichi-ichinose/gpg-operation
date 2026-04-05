#!/bin/bash
set -e

echo "=> GPG/YubiKey ワークフローに必要な依存パッケージをインストールします..."

# 必要なパッケージのリストと、その選定理由（第一原理）
PACKAGES=(
    "gnupg2"          # 暗号化スイートのコア機能
    "pcsc-lite"       # スマートカード（YubiKey）との低レイヤー通信デーモン
    "pcsc-tools"      # スマートカードの接続テストツール (pcsc_scan)
    "yubikey-manager" # YubiKeyの属性設定やファクトリーリセット用 (ykman)
    "paperkey"        # 秘密鍵のバイナリパケットを紙(テキスト)用に抽出・復元するツール
    "zbar"            # WebカメラからQRコードを高速に読み取るツール (zbarcam)
    "qrencode"        # paperkeyの出力をQRコード画像に変換するツール
    "expect"          # gpgの対話型プロンプト(movetocard等)を自動化するためのツール
    "rsync"           # USB間の安全で確実なディレクトリ同期ツール
)

# パッケージのインストール実行
sudo dnf install -y "${PACKAGES[@]}"

# pcscdデーモンの起動と自動起動化（YubiKey認識に必須）
echo "=> pcscd サービスの有効化..."
sudo systemctl enable --now pcscd

echo "--------------------------------------------------"
echo "✅ 全ての依存関係のセットアップが完了しました。"
echo "YubiKeyが認識されているか確認するには 'ykman info' を実行してください。"