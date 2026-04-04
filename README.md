# GPG/SSH 鍵管理スクリプト
chmod +x scripts/gpg/*.sh
chmod +x scripts/ssh/*.sh
## 0. 事前準備
```bash
# === GPG用 ===
export GPG_KEY_NAME="あなたの名前"
export GPG_KEY_EMAIL="あなたのEmail"
# 主鍵バックアップ用のマスターUSB (単一)
export GPG_USB_MOUNT="/mnt/usb_master"
# 副鍵バックアップ用のUSB (複数指定可)
export GPG_USB_MOUNTS="/mnt/usb_master /mnt/usb_replica" 
# フィンガープリント (手順1で設定)
export GPG_FPR="<FINGERPRINT>"

# === SSH用 ===
export SSH_KEY_EMAIL="あなたのEmail"
export SSH_USB_MOUNT="/mnt/usb_master"
```

---
## GPG ワークフロー (`scripts/gpg`)

### 1. 主鍵の生成 (初回のみ)
**スクリプト:** `generate_primary_key.sh`  
**説明:** GPG主鍵を生成し、`GPG_USB_MOUNT`で指定したマスターUSBへバックアップする。  
**コマンド:**
```bash
./scripts/gpg/generate_primary_key.sh
# 表示されたフィンガープリントをコピーし、GPG_FPRに設定しろ
```

### 2. 主鍵が必要な操作 (副鍵の追加など)
RAMディスク上の一時的な環境で、マスターUSBから主鍵を読み込んで安全に操作する。

#### 手順 2.1: RAMディスク環境の準備
```bash
# 1. 一時GPG環境を作成
export GNUPGHOME=$(mktemp -d -p /dev/shm gpg.XXXXXX)
chmod 700 $GNUPGHOME

# 2. マスターUSBから主鍵をインポート
export GPG_USB_MOUNT="/mnt/usb_master" # GPG_USB_MOUNTを使用
./scripts/gpg/import_keys.sh
```

#### 手順 2.2: 主鍵を使った操作の実行
*   **副鍵の追加**
    **スクリプト:** `add_subkeys.sh`  
    **説明:** GPG副鍵を生成し、`GPG_USB_MOUNTS`で指定した全USBへバックアップする。  
    **コマンド:** `./scripts/gpg/add_subkeys.sh`

*   **新しいUSBへの主鍵バックアップ**
    **スクリプト:** `backup_primary_key.sh`  
    **説明:** 主鍵を新しいUSB (`GPG_USB_MOUNT`) にバックアップする。  
    **コマンド:** `./scripts/gpg/backup_primary_key.sh`

#### 手順 2.3: RAMディスク環境の破棄
```bash
rm -rf $GNUPGHOME
unset GNUPGHOME
```

### 3. その他のGPG操作
(内容は変更なしのため省略)
...
---
## SSH ワークフロー (`scripts/ssh`)
(変更なし)
