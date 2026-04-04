# GPG/SSH鍵管理スクリプト

YubiKeyのようなハードウェアキーを使用してGPG鍵とSSH鍵を管理するための一連のスクリプトだ。

## 事前準備

スクリプトを実行する前に、以下の環境変数を設定する必要がある。

```bash
# GPG鍵生成用
export GPG_KEY_NAME="あなたの名前"
export GPG_KEY_EMAIL="あなたのEmail"
export GPG_USB_MOUNT="/mnt/usb" # USBドライブのマウントポイント

# SSH鍵生成用
export SSH_KEY_EMAIL="あなたのEmail"
export SSH_USB_MOUNT="/mnt/usb" # USBドライブのマウントポイント

# (任意) バックアップディレクトリの変更
# デフォルト: $GPG_USB_MOUNT/gpg_backup, $SSH_USB_MOUNT/ssh_backup
export GPG_BACKUP_DIR="/path/to/your/gpg_backup"
export SSH_BACKUP_DIR="/path/to/your/ssh_backup"
```

## 手順

### 1. GPG鍵の生成

新しいGPGの主鍵と副鍵を生成し、USBドライブにバックアップを作成する。

```bash
./scripts/generate_gpg.sh
```

実行後、フィンガープリントが表示される。**このフィンガープリントは次のステップで必要になるため、必ず控えておけ。**

### 2. GPG副鍵のYubiKeyへの移動

`generate_gpg.sh`で生成した副鍵（署名、暗号化）をYubiKeyに移動する。
これにより、物理的なキーがなければ秘密鍵の操作ができなくなり、セキュリティが向上する。

**注意:** `expect`コマンドがインストールされている必要がある。

```bash
# <FINGERPRINT> はステップ1で控えたものに置き換える
./scripts/movetocard.exp.sh <FINGERPRINT>
```

### 3. FIDO2/SSH鍵の生成

YubiKeyをFIDO2デバイスとして使用し、SSH用の`ed25519-sk`タイプの鍵ペアを生成する。
`-O resident`オプションにより、鍵はYubiKey内に保存され、他のマシンでも簡単に利用できるようになる。

```bash
./scripts/generate_ssh_sk.sh
```

実行後、公開鍵 (`id_ed25519_sk.pub`) の内容が表示される。これを接続したいサーバーの `~/.ssh/authorized_keys` に追記しろ。

### 4. (任意) GPG鍵のインポート

別のマシンでGPG鍵を使いたい場合、USBバックアップから鍵をインポートする。

```bash
./scripts/import_gpg.sh
```
