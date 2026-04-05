#!/bin/bash
set -e

: "${GPG_RAMDISK_DIR:?エラー: GPG_RAMDISK_DIR が未設定だ。}"

SOURCE_USB="${1:-}"
if [ -z "$SOURCE_USB" ] || [ ! -d "$SOURCE_USB" ]; then
    echo "エラー: インポート元のUSBマウントポイントを引数で指定しろ。"
    echo "使い方: $0 /mnt/usb_master"
    exit 1
fi

BACKUP_DIR="${SOURCE_USB}/gpg_backup"
if [ ! -d "$BACKUP_DIR" ]; then
    echo "エラー: $BACKUP_DIR が見つからない。"
    exit 1
fi

export GNUPGHOME="$GPG_RAMDISK_DIR"

# === 環境の構築 ===
# ファイルを書き込む前に、必ずディレクトリを生成（存在しない場合のみ作成される）
mkdir -p -m 700 "$GNUPGHOME"

# === scdaemonの競合回避設定 (pcscdを使用) ===
# --- 1. Fedora 最適化設定 (GUI対応版) ---
cat <<EOF > "$GNUPGHOME/scdaemon.conf"
disable-ccid
pcsc-shared
EOF

cat <<EOF > "$GNUPGHOME/gpg-agent.conf"
scdaemon-program /usr/libexec/scdaemon
EOF
echo "=> Fedora 最適化設定を適用した。"

# === 鍵のインポート ===
echo "=> 鍵のインポート..."
gpg --import "$BACKUP_DIR/public.asc"

if [ -f "$BACKUP_DIR/primary_secret.asc" ]; then
    gpg --import "$BACKUP_DIR/primary_secret.asc"
fi

if [ -f "$BACKUP_DIR/subkeys_secret.asc" ]; then
    gpg --import "$BACKUP_DIR/subkeys_secret.asc"
fi

# === 信用度の設定 ===
FPR=$(gpg --list-options show-only-fpr-mbox --list-secret-keys | awk 'NR==1 {print $1}')
if [ -n "$FPR" ]; then
    echo -e "5\ny\n" | gpg --command-fd 0 --edit-key "$FPR" trust
    echo "=> 鍵のTrustレベルをUltimateに設定した。"
fi

echo "=> インポート完了。"