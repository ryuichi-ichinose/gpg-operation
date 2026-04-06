#!/bin/bash
set -e

# 環境変数のチェック
: "${GPG_FPR:?エラー: GPG_FPR が未設定だ。}"
: "${GPG_RAMDISK_DIR:?エラー: GPG_RAMDISK_DIR が未設定だ。}"

# 引数チェック
SOURCE_USB="${1:-}"
QR_DATA="${2:-}"

if [ -z "$SOURCE_USB" ] || [ ! -d "$SOURCE_USB" ]; then
    echo "エラー: USBマウントポイントを第1引数で指定しろ。"
    exit 1
fi

if [ -z "$QR_DATA" ]; then
    echo -n "QRコードの文字列を入力してください: "
    read -r QR_DATA
fi

BACKUP_DIR="${SOURCE_USB}/gpg_backup"
if [ ! -d "$BACKUP_DIR" ]; then
    echo "エラー: $BACKUP_DIR が見つからない。"
    exit 1
fi

# GNUPGHOMEの設定
export GNUPGHOME="$GPG_RAMDISK_DIR"
mkdir -p -m 700 "$GNUPGHOME"

# === Fedora 最適化設定 ===
cat <<EOF > "$GNUPGHOME/scdaemon.conf"
disable-ccid
pcsc-shared
EOF
cat <<EOF > "$GNUPGHOME/gpg-agent.conf"
scdaemon-program /usr/libexec/scdaemon
EOF

# === 復元プロセス ===
echo "=> 公開鍵の変換とQRデータのデコード..."
gpg --dearmor < "$BACKUP_DIR/public.asc" > "$GNUPGHOME/public.gpg"
echo "$QR_DATA" | base64 -d > "$GNUPGHOME/secret_fragment.bin"

echo "=> paperkey による秘密鍵の再構築..."
paperkey --pubring "$GNUPGHOME/public.gpg" \
         --secrets "$GNUPGHOME/secret_fragment.bin" \
         --output "$GNUPGHOME/restored_private.gpg"

echo "=> 復元された秘密鍵をインポート..."
gpg --import "$GNUPGHOME/restored_private.gpg"

# TrustレベルをUltimateに
echo -e "5\ny\n" | gpg --command-fd 0 --edit-key "$GPG_FPR" trust

# === USBへの書き戻しセクション ===
echo "=> 復元した主鍵をUSBへバックアップ ($BACKUP_DIR/primary_secret.asc)..."

# 既存ファイルがある場合はバックアップを作成
if [ -f "$BACKUP_DIR/primary_secret.asc" ]; then
    mv "$BACKUP_DIR/primary_secret.asc" "$BACKUP_DIR/primary_secret.asc.bak"
fi

# 秘密鍵をASCII Armor形式でエクスポート
gpg --export-secret-keys --armor "$GPG_FPR" > "$BACKUP_DIR/primary_secret.asc"

echo "=> USBへの書き戻しが完了した。"

# 一時バイナリの抹消
shred -u "$GNUPGHOME/public.gpg" "$GNUPGHOME/secret_fragment.bin" "$GNUPGHOME/restored_private.gpg"

echo "--------------------------------------------------"
echo "=> 全工程完了。USB内の秘密鍵が更新されました。"
gpg -K