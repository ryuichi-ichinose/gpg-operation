# 究極のGPG/SSH鍵管理ワークフロー

オフラインマスター鍵とYubiKeyで、安全なGPG/SSH鍵を運用するための手順書。
**書かれた順にスクリプトを実行するだけでよい。**

---

### 0. 事前準備 (最初に一度だけ)

このワークフローを開始する前に、YubiKeyの初期設定を行う。

1.  **YubiKeyのPIN/リトライ回数設定**
    PINの試行回数を増やしておくと、ロックアウトのリスクを大幅に減らせる。`gpg --card-edit` を使って設定する。

    ```bash
    gpg --card-edit
    # gpg/card> admin
    # Admin commands are allowed
    # gpg/card> passwd
    # 1 - change PIN
    # 2 - unblock PIN
    # 3 - change Admin PIN
    # 4 - set token
    # Q - quit
    # Your selection? 1
    # PIN changed.
    # Your selection? 3
    # Admin PIN changed.
    #
    # gpg/card> login
    #PINs don't match
    #
    # gpg/card> factory-reset
    #
    # gpg/card> set-pin-retries 99 99 99
    #
    # gpg/card> quit
    ```

2.  **YubiKeyの鍵属性を設定**
    このワークフローは `ed25519` 鍵を基本とする。以下のスクリプトを実行し、YubiKeyが `ed25519` 鍵を受け入れられるように設定する。

    ```bash
    ./scripts/gpg/setup_yubikey.sh
    ```

3.  **環境設定ファイルを作成**
    リポジトリのルートに `.env` ファイルを以下の内容で作成する。

    ```bash
    # .env
    # --- GPG/SSH共通のアイデンティティ ---
    export GPG_KEY_NAME="あなたの名前"
    export GPG_KEY_EMAIL="your@email.com"
    export SSH_KEY_EMAIL="your@email.com"

    # --- この後のSTEP I-1で取得するフィンガープリントを設定 ---
    export GPG_FPR=""

    # --- スクリプトが使用する固定パス (変更不要) ---
    export GPG_RAMDISK_DIR="/dev/shm/gpg_workspace"
    ```

4.  **スクリプトに実行権限を付与**

    ```bash
    chmod +x scripts/gpg/*.sh scripts/ssh/*.sh
    ```

---

### 補足: USBデバイスのマウント手順 (Linuxの例)

このワークフローの各スクリプトは、`<マスターUSBのパス>` のような引数を取る。これは、USBデバイスがファイルシステム上の特定のディレクトリ（例: `/mnt/usb_master`）に接続（マウント）されていることを前提としている。

以下に、USBデバイスをマウントする一般的な手順を示す。

1.  **デバイス名を確認する**
    USBをPCに接続し、以下のコマンドでデバイス名（例: `/dev/sdc1`）を探す。
    ```bash
    lsblk
    ```

2.  **マウントポイント（接続先のディレクトリ）を作成する**
    ```bash
    sudo mkdir -p /mnt/usb_master
    ```

3.  **デバイスをマウントする**
    手順1で確認したデバイス名を、手順2で作成したマウントポイントに接続する。
    ```bash
    # 使用法: sudo mount <デバイス名> <マウントポイント>
    sudo mount /dev/sdc1 /mnt/usb_master
    ```
    これで、各スクリプトに引数として `/mnt/usb_master` を渡せるようになる。

4.  **作業後にアンマウントする**
    安全に取り外すために、作業が終わったらアンマウントする。
    ```bash
    sudo umount /mnt/usb_master
    ```

---

### I. GPG鍵セットアップ (初回のみ)

#### STEP 1: 主鍵の生成とバックアップ (オフライン推奨)

GPGの核となる「マスター鍵」を生成し、安全なUSBに保管する。

```bash
  source .env  # .envを読み込む
./scripts/gpg/generate_primary_key.sh <マスターUSBのパス>
```

=> 実行後、画面に表示される**フィンガープリント**をコピーし、`.env`ファイルの`GPG_FPR`に貼り付けて保存する。

#### STEP 2: 副鍵のセットアップ

次に、日常的に使うための副鍵を生成し、YubiKeyに書き込む。この一連の作業も「準備→操作→後始末」のパターンで行う。

---
##### **準備: 主鍵のインポート**
```bash
# マスターUSBから主鍵を一時的に読み込む
# source .env
./scripts/gpg/import_keys.sh <マスターUSBのパス>
```

---
##### **操作: 副鍵の生成とYubiKeyへの移動**
```bash
# 1. 副鍵を生成し、全バックアップUSBに保存
./scripts/gpg/add_subkeys.sh <マスターUSBのパス> [他のバックアップUSB...]

# 2. YubiKeyをPCに挿し、副鍵を書き込む (警告: この操作は元に戻せない)
./scripts/gpg/movetocard_subkeys.exp.sh
```

---
##### **後始末: 環境の破棄**
**【重要】** 作業が終わったら、必ずPCのRAM上から主鍵を含む作業環境を完全に消去する。
```bash
./scripts/gpg/cleanup_ramdisk.sh
```

---

### II. SSH鍵セットアップ (YubiKey)
#### STEP 1: YubiKeyにSSH鍵を直接生成

```bash
# YubiKeyをPCに挿し、タッチに備える
# source .env
./scripts/ssh/generate_ssh_sk.sh <マスターUSBのパス>
```

=> 実行後、画面に表示される**公開鍵** (`ssh-ed25519-sk...`) をサーバーの`~/.ssh/authorized_keys`に登録する。

#### STEP 2: 新しいPCでSSH鍵を使う

YubiKeyを新しいPCに挿して、以下のコマンドを実行するだけ。

```bash
ssh-keygen -K
```

---

### III. 主鍵を要するメンテナンス操作

マスターUSBに保管された主鍵は、様々なメンテナンス操作の「鍵」となる。
以下の操作はすべて、**「準備 → 操作 → 後始末」**という一貫した流れで行う。

---
#### **STEP 1: 準備 (主鍵のインポート)**

まず、マスターUSB（主鍵と副鍵のバックアップを含む）をPCに接続・マウントし、以下のコマンドで一時的な作業環境を構築する。

```bash
# source .env
./scripts/gpg/import_keys.sh <マスターUSBのパス>
```
=> これで、PCのRAM上に安全なGPG作業環境ができた。次に、以下のいずれかの操作を実行する。

---
#### **STEP 2: 操作 (目的を選択)**

##### **目的A: YubiKeyを交換・復旧する**
YubiKeyを紛失・破損した場合、このコマンドでバックアップから新しいYubiKeyへ副鍵を復元する。

```bash
# 新しいYubiKeyをPCに挿してから実行
./scripts/gpg/movetocard_subkeys.sh
```

##### **目的B: マスター鍵のバックアップを追加する**
マスターUSBのクローンを、別の新しいUSBに作成する。

```bash
./scripts/gpg/backup_primary_key.sh <新しいバックアップUSBのパス>
```

##### **目的C: バックアップUSBを安全に同期する**
マスターUSBの内容を、既存の複製USBに安全に同期（rsync）する。

```bash
./scripts/gpg/safe_usb_sync.sh <マスターUSBのパス/gpg_backup> <複製USBのパス/gpg_backup>
```

---
#### **STEP 3: 後始末 (環境の破棄)**

**【重要】** 上記の操作が完了したら、**必ず**以下のコマンドを実行し、PCのRAM上から主鍵を含む作業環境を完全に消去する。

```bash
./scripts/gpg/cleanup_ramdisk.sh
```
=> これでメンテナンス操作は完了だ。

### IV 究極のフェイルセーフ: 紙(QRコード)からのマスター鍵復元
すべてのバックアップUSBが破損・紛失した最悪の事態に備えた、紙媒体からのコールドブート手順だ。印刷されたQRコード（Base64化された秘密鍵の断片）と公開鍵を結合し、RAM上でマスター鍵を完全復元して新しいUSBへ書き戻す。

1. 準備 (公開鍵の配置とQRスキャン)
新しいUSBの準備:
新しいUSBをマウントし、その中に gpg_backup ディレクトリを作成して公開鍵（public.asc）を配置しておく。
※ paperkey は公開鍵の構造を鋳型として秘密鍵を再構築するため、公開鍵データが必須となる。

QRコードの読み取り:
Webカメラ等を使用して、印刷されたQRコードからBase64文字列を読み取っておく。

Bash
# 例: Webカメラからリアルタイムにデコードする場合
zbarcam /dev/video0
2. 操作 (復元とUSBへのバックアップ)
準備したUSBのマウントポイントと、読み取った文字列を引数にしてスクリプトを実行する。

Bash
# source .env
./scripts/gpg/restore_and_backup.sh <新しいUSBのパス> "読み取ったBase64文字列"

# ※ 第2引数(文字列)を省略した場合、対話型プロンプトで入力を求められる。
=> 実行後、RAMディスク上でバイナリへの再構築と結合が行われ、指定したUSBの gpg_backup/primary_secret.asc としてマスター鍵が自動的に書き戻される。

3. 後始末 (自動消去)
この復元スクリプトは、処理の最後に shred コマンドを用いて、RAM上に展開された秘密の断片（.bin）や一時的なマスター鍵を自動的に上書き消去するよう設計されている。
実行が正常終了した時点で、復旧と痕跡の隠滅は完了している。以降は、復元されたUSBを用いて「III. 主鍵を要するメンテナンス操作」を再開できる。

### V. 応用: Gitでコミットに署名する

このワークフローでセットアップした鍵は、Gitのコミット署名に利用できる。これにより、お前のコミットが本当に自分自身によって行われたことを証明できる。

#### 1. YubiKeyからGPGキーを認識させる

YubiKeyをPCに接続し、以下のコマンドを実行する。`ssb>`（secret subkey stub）で始まる行が表示されれば、PCはYubiKey上の副鍵を正しく認識している。

```bash
gpg --list-secret-keys
```
=> この出力から、**主鍵のフィンガープリント**をコピーしておく。

#### 2. Gitに署名キーを設定する

コピーしたフィンガープリントをGitのグローバル設定に登録する。

```bash
# git config --global user.signingkey <あなたの主鍵のフィンガープリント>
git config --global user.signingkey ABCDE...
```
**注意:** 副鍵ではなく、**主鍵**のフィンガープリントを指定する。GPGが自動的に署名に適した副鍵を選択してくれる。

#### 3. 全てのコミットで自動署名を有効にする (推奨)

この設定を行うと、`git commit` を実行するたびに自動でGPG署名が行われるようになる。

```bash
git config --global commit.gpgsign true
```

これでセットアップは完了だ。`git commit` を実行するとYubiKeyのPIN入力が求められ、タッチすることでコミットが署名される。
