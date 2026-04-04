# GPG/SSH鍵管理スクリプト

YubiKeyのようなハードウェアキーを使用してGPG鍵とSSH鍵をセキュアに管理するための一連のスクリプトだ。

## ワークフローの考え方

- **GPG**: `生成 → バックアップ → ハードウェアキーへ移動` というワークフロー。主鍵はPCに残し、副鍵をYubiKeyに移動する。
- **SSH**: `ハードウェアキー上で直接生成 → ハンドルをバックアップ` というワークフロー。秘密鍵は決してYubiKeyから出ない。

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
```

---

## 手順

### 1. GPG鍵の生成 (`generate_gpg.sh`)

新しいGPGの主鍵と副鍵（署名・暗号化）を生成し、失効証明書などと共にUSBドライブにバックアップを作成する。

```bash
./scripts/generate_gpg.sh
```

実行後、フィンガープリントが表示される。**このフィンガープリントは次のステップで必要になるため、必ず控えておけ。**

### 2. GPG副鍵のYubiKeyへの移動 (`movetocard_gpg.exp.sh`)

ステップ1で生成したGPG副鍵をYubiKeyに移動する。これにより、物理的なキーがなければ秘密鍵の操作ができなくなる。

**注意:** `expect`コマンドがインストールされている必要がある。

```bash
# <FINGERPRINT> はステップ1で控えたものに置き換える
./scripts/movetocard_gpg.exp.sh <FINGERPRINT>
```

### 3. FIDO2/SSH鍵の生成 (`generate_ssh_sk.sh`)

YubiKeyのFIDO2機能を使って、**YubiKey内部で直接**SSH用の鍵ペアを生成する。
`-O resident`オプションにより、鍵はYubiKey内に常駐し、他のマシンでも利用可能になる。

USBには、秘密鍵そのものではなく、YubiKey内の秘密鍵を操作するための**ハンドルファイル** (`id_ed25519_sk`) と公開鍵 (`id_ed25519_sk.pub`) がバックアップされる。

```bash
./scripts/generate_ssh_sk.sh
```

実行後、表示される公開鍵を接続したいサーバーの `~/.ssh/authorized_keys` に追記しろ。

---

## マシン移行時の手順

### GPG鍵のインポート (`import_gpg.sh`)

新しいマシンでGPG鍵を使いたい場合、USBバックアップから鍵をインポートする。

```bash
./scripts/import_gpg.sh
```

### SSH鍵ハンドルの読み込み (`load_ssh_sk_from_yubikey.sh`)

新しいマシンでYubiKeyを使ったSSH認証を行いたい場合、このスクリプトを実行してYubiKeyから鍵のハンドル情報をPCの `~/.ssh` ディレクトリに読み込む。

```bash
./scripts/load_ssh_sk_from_yubikey.sh
```
