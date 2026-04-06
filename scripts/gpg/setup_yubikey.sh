#!/bin/bash
set -e

# --- 0. 環境設定 ---
: "${GPG_RAMDISK_DIR:?エラー: GPG_RAMDISK_DIR が未設定だ。}"
export GNUPGHOME="$GPG_RAMDISK_DIR"
mkdir -p -m 700 "$GNUPGHOME"

# TODO: 以下の設定はFedora系に特化している。他のディストリビューション
# (Debian/Ubuntuなど)では `scdaemon-program` のパスが異なる可能性があるため、
# 環境に応じた修正が必要。
# --- 1. Fedora 最適化設定 ---
cat <<EOF > "$GNUPGHOME/scdaemon.conf"
disable-ccid
pcsc-shared
EOF

cat <<EOF > "$GNUPGHOME/gpg-agent.conf"
scdaemon-program /usr/libexec/scdaemon
EOF

gpgconf --kill all
sleep 1

echo "=> YubiKey を ECC (Ed25519/Curve25519) モードに切り替えます..."
echo "※ GUIで Admin PIN (12345678) を求められたら入力しろ。"

# --- 2. Expect セクション (力技のシーケンス) ---
expect <<EOF
set timeout 30
spawn gpg --card-edit

expect "gpg/card>"
send "admin\r"

expect "gpg/card>"
send "key-attr\r"

# --- (1) Signature Key ---
# アルゴリズム選択 (2: ECC)
expect "Your selection? "
send "2\r"
# 曲線選択 (1: Ed25519)
expect "Your selection? "
send "1\r"

# --- (2) Encryption Key ---
# アルゴリズム選択 (2: ECC)
expect "Your selection? "
send "2\r"
# 曲線選択 (1: Curve25519)
expect "Your selection? "
send "1\r"

# --- (3) Authentication Key ---
# アルゴリズム選択 (2: ECC)
expect "Your selection? "
send "2\r"
# 曲線選択 (1: Ed25519)
expect "Your selection? "
send "1\r"

# 完了
expect "gpg/card>"
send "quit\r"
expect eof
EOF

echo "------------------------------------------------"
echo "完了。属性が ed25519 / cv25519 になっているか確認しろ:"
gpg --card-status | grep "Key attributes"
echo "------------------------------------------------"