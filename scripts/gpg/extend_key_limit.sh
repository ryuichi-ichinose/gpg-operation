#!/bin/bash
set -e

: "${GPG_FPR:?エラー: GPG_FPR が未設定だ。}"
: "${GPG_RAMDISK_DIR:?エラー: GPG_RAMDISK_DIR が未設定だ。}"

TARGET_USB="${1:-}"
if [ -z "$TARGET_USB" ] || [ ! -d "$TARGET_USB" ]; then
    echo "エラー: マスター鍵が入っているUSBマウントポイントを指定しろ。"
    exit 1
fi

export GNUPGHOME="$GPG_RAMDISK_DIR"
BACKUP_DIR="${TARGET_USB}/gpg_backup"

# 1. マスター鍵のインポート（期限更新には主鍵の秘密鍵が必須）
echo "=> マスター鍵をインポート中..."
gpg --import "$BACKUP_DIR/primary_secret.asc"
gpg --import "$BACKUP_DIR/subkeys_secret.asc"

# 2. ユーザーへのガイド
echo "------------------------------------------------------------------"
echo "===> GPGキーの有効期限を更新します <==="
echo "------------------------------------------------------------------"
echo "これから対話的な GPG プロンプトを開始します。"
echo "以下の手順に従って、各キーの有効期限を更新してください。"
echo ""
echo "  1. gpg> プロンプトで 'list' と入力してキーの一覧を確認します。"
echo "  2. 主鍵を更新するには、そのまま 'expire' と入力します。"
echo "     - 有効期限 ('1y' など) を入力し、確認 ('y') します。"
echo "  3. 副鍵を更新するには、'key <N>' でキーを選択します（例: 'key 1'）。"
echo "     - アスタリスク (*) が選択したキーの横に移動したことを確認します。"
echo "     - 'expire' と入力し、同様に有効期限を設定します。"
echo "  4. **すべてのキー** に対してこのプロセスを繰り返します。"
echo "  5. 最後に 'save' と入力して変更を保存し、プロンプトを終了します。"
echo "------------------------------------------------------------------"
echo "現在のキーの状態:"
gpg --list-keys "$GPG_FPR"
echo "------------------------------------------------------------------"
read -p "準備ができたら Enter を押して GPG プロンプトを開始します..."

# 3. 対話的セッションの開始
# --tty オプションで現在のターミナルを明示的に指定する
gpg --tty `tty` --edit-key "$GPG_FPR"


# 4. 更新された鍵をUSBに書き戻す
echo "=> 更新された鍵を USB に上書きエクスポート中..."
gpg --armor --export "$GPG_FPR" > "$BACKUP_DIR/public.asc"
gpg --armor --export-secret-keys "$GPG_FPR" > "$BACKUP_DIR/primary_secret.asc"
gpg --armor --export-secret-subkeys "$GPG_FPR" > "$BACKUP_DIR/subkeys_secret.asc"

sync
echo "------------------------------------------------"
echo "✅ 更新完了。新しい有効期限を確認しろ:"
gpg --list-keys "$GPG_FPR"
echo "------------------------------------------------"
echo "※ 注意: ホストPCにも 'make import-keys-to-host' で新しい公開鍵を反映させるのを忘れるな。"