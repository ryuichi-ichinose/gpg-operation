#!/bin/bash
set -e

: "${GPG_FPR:?エラー: GPG_FPR が未設定だ。}"
: "${GPG_RAMDISK_DIR:?エラー: GPG_RAMDISK_DIR が未設定だ。}"

export GNUPGHOME="$GPG_RAMDISK_DIR"

# TODO: 以下の設定はFedora系に特化している。他のディストリビューション
# (Debian/Ubuntuなど)では `scdaemon-program` のパスが異なる可能性があるため、
# 環境に応じた修正が必要。
# Fedora 最適化設定
cat <<EOF > "$GNUPGHOME/scdaemon.conf"
disable-ccid
pcsc-shared
EOF

cat <<EOF > "$GNUPGHOME/gpg-agent.conf"
scdaemon-program /usr/libexec/scdaemon
EOF

gpgconf --kill all
sleep 1

echo "=> 副鍵をYubiKeyへ移動する（上書き対応版）..."

expect <<EOF
set timeout -1
spawn gpg --edit-key $GPG_FPR

# --- 1枚目の副鍵 (Sign) ---
expect "gpg>"
send "key 1\r"
expect "gpg>"
send "keytocard\r"
expect "Your selection?"
send "1\r"

# 上書き確認が出た場合の処理
expect {
    "Replace existing key? (y/N) " {
        send "y\r"
        exp_continue
    }
    "gpg>"
}

# --- 2枚目の副鍵 (Encrypt) ---
send "key 1\r"
expect "gpg>"
send "key 2\r"
expect "gpg>"
send "keytocard\r"
expect "Your selection?"
send "2\r"

# 上書き確認が出た場合の処理 (Encrypt用)
expect {
    "Replace existing key? (y/N) " {
        send "y\r"
        exp_continue
    }
    "gpg>"
}

send "save\r"
expect eof
EOF

echo "=> 工程完了。"
gpg --list-secret-keys "$GPG_FPR"