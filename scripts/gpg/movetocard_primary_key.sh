#!/bin/bash
set -e

# --- 0. 環境変数のチェック ---
: "${GPG_FPR:?エラー: GPG_FPR が未設定だ。}"
: "${GPG_RAMDISK_DIR:?エラー: GPG_RAMDISK_DIR が未設定だ。}"

export GNUPGHOME="$GPG_RAMDISK_DIR"
mkdir -p -m 700 "$GNUPGHOME"

# TODO: 以下の設定はFedora系に特化している。他のディストリビューション
# (Debian/Ubuntuなど)では `scdaemon-program` のパスが異なる可能性があるため、
# 環境に応じた修正が必要。
# --- 1. Fedora 最適化設定 (GUI対応版) ---
cat <<EOF > "$GNUPGHOME/scdaemon.conf"
disable-ccid
pcsc-shared
EOF

cat <<EOF > "$GNUPGHOME/gpg-agent.conf"
scdaemon-program /usr/libexec/scdaemon
EOF

echo "=> Fedora 最適化設定を適用した。"

# デーモンをリフレッシュ
gpgconf --kill all
sleep 1

# --- 2. 最終警告とガイド ---
echo "----------------------------------------------------------------"
echo "【警告：マスター鍵の引越し】"
echo "これより主鍵（Master Key）を YubiKey へ移動する。"
echo ""
echo "GUIのポップアップが出るので、以下を入力しろ："
echo "1. GPG Passphrase: マスター鍵のパスワード"
echo "2. Admin PIN: YubiKey管理者PIN（デフォルト: 12345678）"
echo ""
echo "※ YubiKeyが光ったら物理タッチを忘れずに。"
echo "----------------------------------------------------------------"
echo "=> 主鍵をYubiKeyへ移動する..."

# --- 3. Expect による自動対話セクション ---
expect <<EOF
set timeout -1
# GUI pinentry を使うため --pinentry-mode loopback は指定しない
spawn gpg --edit-key $GPG_FPR

expect "gpg>"
send "keytocard\r"

# 主鍵移動特有の複数のプロンプトに対応
expect {
    "Really move the primary key?" {
        send "y\r"
        exp_continue
    }
    "Replace existing key? (y/N) " {
        send "y\r"
        exp_continue
    }
    "Your selection?" {
        # 主鍵は通常 Signature スロット(1)に格納する
        send "1\r"
        exp_continue
    }
    "gpg>"
}

# GUI入力と物理タッチが完了して 'gpg>' に戻るのを待つ
send "save\r"
expect eof
EOF

echo "=> 処理完了。主鍵の状態を確認しろ。"
# sec の横に '>' が付いていれば、主鍵の実体は YubiKey 内にある（スタブ化成功）。
gpg --list-secret-keys "$GPG_FPR"