# GPG & YubiKey Operation Guide

このリポジトリは、GPGキーの生成、管理、そしてYubiKeyへの移行を自動化するためのスクリプト群です。

## 0. 前提条件

### 0.1. 環境変数の設定
最初に、プロジェクトのルートに`.env`ファイルを作成し、以下の変数を設定してください。

```bash
# .envファイル の例

# GPGキーの基本情報
export GPG_KEY_NAME="your name"
export GPG_KEY_EMAIL="your mail address"
# ※ 主鍵生成後に表示されるフィンガープリントを設定
export GPG_FPR=""

# SSHキーの情報
export SSH_KEY_EMAIL="your mail address"

# 一時作業ディレクトリ（RAMディスクを推奨）
export GPG_RAMDISK_DIR="/dev/shm/gpg_workspace"
```

### 0.2. OSに関する注意
このツールのスクリプトは **Fedora Linux** をベースに開発・テストされています。
特に、GPGデーモン(`scdaemon`)の設定がFedoraのパス (`/usr/libexec/scdaemon`) に依存しています。

Debian, Ubuntu, Arch Linuxなどの他のディストリビューションで使用する場合は、スクリプト内の以下の部分を環境に合わせて修正する必要があります。
```bash
# e.g., scripts/gpg/import_keys.sh

# TODO: 以下の設定はFedora系に特化している...
cat <<EOF > "$GNUPGHOME/gpg-agent.conf"
scdaemon-program /usr/libexec/scdaemon # <- このパスを修正
EOF
```

---

## 1. 🛠️ 初期セットアップ (初回のみ)

### 1.1. GPGキーペアの生成 (主鍵 + 副鍵)

1.  **主鍵 (Primary Key) の生成**
    - `certify`権限のみを持つマスターキーです。

    ```bash
    make generate-primary-key USB="your/usb/path"
    ```
    > **重要:** このコマンド実行後、画面に表示される **フィンガープリント (FPR)** をコピーし、`.env`ファイルの`GPG_FPR`に設定してください。

2.  **副鍵 (Subkeys) の生成**
    - `sign`, `encrypt`, `authenticate` 権限を持つ日常利用のキーです。
    - **有効期限は1年**に設定されます。

    ```bash
    make add-subkeys USB="your/usb/path"
    ```

3.  **作業環境のクリーンアップ**
    - RAMディスク上の一時ファイルを削除します。

    ```bash
    make cleanup
    ```

### 1.2. YubiKey の初期化

- YubiKeyの鍵スロットを、GPGで推奨される`ed25519`および`cv25519` (Curve25519) に設定します。

```bash
make setup-yubikey
```

---

## 2. 🔑 YubiKey への移行

### 2.1. 副鍵のYubiKeyへの移動

1.  **GPGキーのインポート**
    - バックアップUSBから作業用のRAMディスクへキーを読み込みます。

    ```bash
    make import-keys USB="your/usb/path"
    ```

2.  **副鍵をYubiKeyへ移動**
    > **警告:** この操作は **不可逆** です。一度移動した副鍵はYubiKeyから取り出せません。

    ```bash
    make move-subkeys-to-card
    ```

3.  **作業環境のクリーンアップ**

    ```bash
    make cleanup
    ```

### 2.2. ホストPCへの公開鍵設定

- YubiKeyに紐付けられたGPGキーを、日常的に使用するPCに設定します。

1.  **公開鍵とスタブのインポート**
    - これにより、PCは「秘密鍵がYubiKeyにある」ことを認識します。

    ```bash
    make import-keys-to-host USB="your/usb/path"
    ```

2.  **作業環境のクリーンアップ**

    ```bash
    make cleanup
    ```

3.  **公開鍵のエクスポート**
    - GitHubやKey Serverに登録するために、公開鍵をクリップボードにコピーします。

    ```bash
    gpg --armor --export $GPG_FPR | xclip -sel clip
    ```

---

## 3. 🔄 定期メンテナンス (1年周期)

### 3.1. 有効期限の更新

1.  **GPGキーのインポート**

    ```bash
    make import-keys USB="your/usb/path"
    ```

2.  **有効期限の延長 (ガイド付き対話モード)**
    - 対話的なGPGプロンプトが起動します。
    - 画面に表示される指示に従い、各キー（主鍵と副鍵）の有効期限を個別に設定してください。

    ```bash
    make extend-key-limit USB="your/usb/path"
    ```

3.  **作業環境のクリーンアップ**

    ```bash
    make cleanup
    ```

4.  **新しい公開鍵をホストに反映**

    ```bash
    make import-keys-to-host USB="your/usb/path"
    ```

5.  **公開鍵の再配布**
    - GitHubやKey Serverに、更新された新しい公開鍵を再度アップロードしてください。

---

## 4. 🆘 究極の復旧 (QRコード)

- 物理的な紙のバックアップから主鍵を復元します。

1.  **QRコードの読み取り**
    - `zbar`などのツールでQRコードを読み取り、base64エンコードされた文字列を取得します。

2.  **キーの復元**

    ```bash
    make restore-from-qr USB="/run/media/ichinose/NEW_USB" QR_DATA="<読み取った文字列>"
    ```

---

## 5. 🚀 SSH (FIDO2) 管理

### 5.1. SSHキーの生成と利用

1.  **YubiKey内でSSHキーを生成**
    - FIDO2/U2F (sk) タイプのSSHキーを生成し、バックアップUSBに秘密鍵ハンドルを保存します。

    ```bash
    make generate-ssh-key USB="your/usb/path"
    ```

2.  **新しいPCでSSHキーを利用**
    - 別のPCでこのSSHキーを使いたい場合、バックアップUSBからキーハンドルを読み込みます。

    ```bash
    ssh-keygen -K
    ```
---

## 6. 🔄 YubiKeyの切り替え

PCに登録されているGPGキーの参照先を、新しいYubiKeyに切り替える際の手順です。

1.  **古いYubiKeyのスタブ（参照情報）を削除**
    - `~/.gnupg/private-keys-v1.d/`にある`.key`ファイルは、秘密鍵そのものではなく「秘密鍵がどのYubiKeyにあるか」という情報を持っています。これを削除します。
    > **Note:** 秘密鍵の実体はYubiKeyやバックアップUSBにあるため、この操作は安全です。

    ```bash
    rm ~/.gnupg/private-keys-v1.d/*.key
    ```

2.  **GPGデーモンの再起動と新しいYubiKeyの認識**
    - 新しいYubiKeyをPCに接続した状態で、GPGのプロセスを再起動します。

    ```bash
    gpgconf --kill all
    ```
    - `gpg --card-status` を実行して、新しいYubiKeyが正しく認識されていることを確認します。

    ```bash
    gpg --card-status
    ```
    これで、GPGは新しいYubiKeyを秘密鍵の場所として認識するようになります。
