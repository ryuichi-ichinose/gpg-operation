# GPGワークフロー テスト手順

このドキュメントは、GPGスクリプトの全ワークフローを安全にテストする手順を示す。

## 1. テスト環境の準備
```bash
mkdir -p /tmp/gpg_test_area
cd /tmp/gpg_test_area
mkdir -p master_usb replica_usb_1 replica_usb_2

export GPG_KEY_NAME="Test User"
export GPG_KEY_EMAIL="test@example.com"
```

## 2. テストの実行

**重要:** 以下のコマンド内のスクリプトパスは、**絶対パスで指定する**必要がある。
このテスト手順では `/tmp` 内で作業するため、相対パスではスクリプトを見つけられない。
(例: `/home/your-user/path/to/gpg_operation/scripts/gpg/generate_primary_key.sh`)

### 手順 2.1: 主鍵の初回生成
`generate_primary_key.sh` は単一の `GPG_USB_MOUNT` を使う。
```bash
export GNUPGHOME="$(pwd)/gpg_home_initial_creation"
export GPG_USB_MOUNT="$(pwd)/master_usb" # 単数形
mkdir -p -m 700 "$GNUPGHOME"
/path/to/your/scripts/gpg/generate_primary_key.sh

export GPG_FPR="<ここに表示されたフィンガープリントを貼る>"

rm -rf $GNUPGHOME
unset GNUPGHOME
```

### 手順 2.2: 副鍵の追加 (RAMディスク利用のテスト)
ここからは複数のUSBを扱う `GPG_USB_MOUNTS` を使う。

#### A: 一時環境の準備 (主鍵のインポート)
```bash
export GNUPGHOME="$(pwd)/gpg_home_ramdisk_sim"
chmod 700 $GNUPGHOME

# インポート元としてマスターUSBを単数形で指定
export GPG_USB_MOUNT="$(pwd)/master_usb"
/path/to/your/scripts/gpg/import_keys.sh
```

#### B: 副鍵の追加を実行
```bash
# バックアップ先として全USBを複数形で指定
export GPG_USB_MOUNTS="$(pwd)/master_usb $(pwd)/replica_usb_1"
/path/to/your/scripts/gpg/add_subkeys.sh

# バックアップを確認
ls -l master_usb/gpg_backup/subkeys_secret.asc
ls -l replica_usb_1/gpg_backup/subkeys_secret.asc
```

#### C: 一時環境の破棄
```bash
rm -rf $GNUPGHOME
unset GNUPGHOME
```

## 3. 後始末 (クリーンアップ)
```bash
cd /tmp
rm -rf /tmp/gpg_test_area
unset GPG_KEY_NAME GPG_KEY_EMAIL GPG_USB_MOUNT GPG_USB_MOUNTS GPG_FPR
echo "=> クリーンアップ完了。"
```
---
## 4. (参考) テスト用YubiKeyの初期化

**警告: 以下の操作は取り消し不可能だ。テスト用のYubiKey以外では絶対に実行するな。**

テストで利用したYubiKeyを工場出荷状態に戻す場合に実行する。
`yubikey-manager` が必要だ (`pip install yubikey-manager`)。

### OpenPGP機能のリセット (GPG鍵)
テストでYubiKeyに移動したGPG鍵をすべて削除する。
```bash
ykman openpgp reset
```

### FIDO2機能のリセット (SSH鍵)
テストでYubiKeyに生成したSSH鍵や、WebAuthnのテスト認証情報をすべて削除する。
```bash
ykman fido reset
```
