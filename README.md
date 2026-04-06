.envの例
export GPG_KEY_NAME="your name"
export GPG_KEY_EMAIL="your mail address"
export GPG_RAMDISK_DIR="/dev/shm/gpg_workspace"
export GPG_FPR=""
export SSH_KEY_EMAIL="your mail address"

🛠️ 1. 初期セットアップ (初回のみ)
鍵の生成 (Primary & Subkeys)
Bash
# 1. プライマリーキー生成
make generate-primary-key USB="your/usb/path"
# ※ 画面の FPR を .env の GPG_FPR に追記

# 2. 副鍵生成
make add-subkeys USB="your/usb/path"

# 3. 作業環境削除
make cleanup
YubiKey デバイス初期化
Bash
# YubiKeyをed25519モードに設定
make setup-yubikey
🔑 2. YubiKey への移行
副鍵をハードウェアに流し込む
Bash
# 1. キーをRAMへインポート
make import-keys USB="your/usb/path"

# 2. 副鍵をYubiKeyへ移動 (※不可逆操作)
make move-subkeys-to-card

# 3. 作業環境削除
make cleanup
ホスト PC への反映 & 公開鍵配置
Bash
# 1. ホストに公開鍵とスタブをインポート
make import-keys-to-host USB="your/usb/path"

# 2. クリーンアップ
make cleanup

# 3. 公開鍵をクリップボードにコピー (GitHub / keys.openpgp.org 用)
gpg --armor --export $GPG_FPR | xclip -sel clip
🔄 3. 定期メンテナンス (1年周期)
有効期限の更新
Bash
# 1. RAMへインポート
make import-keys USB="your/usb/path"

# 2. 期限更新 (1y延長)
make renew-keys USB="your/usb/path"

# 3. 作業環境削除
make cleanup

# 4. 新しい公開鍵をホストに反映
make import-keys-to-host USB="your/usb/path"

# 5. 公開鍵を再配置 (GitHub / Keyserver)
# ※ 2-3 のコマンドでコピーして再アップロード
💾 4. USB 冗長化 (バックアップ)
マスター USB の同期
Bash
# マスターから複製用USBへ同期
make sync-backup SRC_USB="your/usb/path" DST_USB="/run/media/ichinose/KIOXIA"
🆘 5. 究極の復旧 (QRコード)
紙媒体からのマスター鍵復活
Bash
# 1. zbar 等でQRを読み込み、結果の文字列をコピー
# 2. 公開鍵が import された状態で実行
make restore-from-qr USB="/run/media/ichinose/NEW_USB" QR_DATA="<読み取った文字列>"
🚀 6. SSH (FIDO2) 管理
SSH 鍵の生成と反映
Bash
# 1. YubiKey内で生成 & USBへバックアップ
make generate-ssh-key USB="your/usb/path"

# 2. 新しいPC環境の .ssh ディレクトリに反映
ssh-keygen -K