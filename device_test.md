# Real-Device Test Procedure

This document outlines the end-to-end test procedure for generating GPG keys and provisioning them to a YubiKey using the provided `Makefile` targets. **This is a test, and all created keys and backups should be securely destroyed afterward.**

## 1. Prerequisites

### 1.1. Install Dependencies
Ensure all required tools (like `gpg`, `qrencode`, `ykman`, etc.) are installed.

```bash
make install-deps
```

### 1.2. Set Up Environment
Create a `.env` file in the project root with temporary, test-only values.

```bash
# .env
export GPG_KEY_NAME="Test User"
export GPG_KEY_EMAIL="test@example.com"
export GPG_RAMDISK_DIR="/dev/shm/gpg_workspace"
export GPG_FPR=""
export SSH_KEY_EMAIL="test@example.com"
```
> **Note:** Initially, `GPG_FPR` is left empty.

---

## 2. Key Generation and Backup

### 2.1. Generate Primary Key
This creates a test GPG primary key and backs it up to the specified USB drive.

-   **Command:**
    ```bash
    make generate-primary-key USB="/path/to/your/usb"
    ```
-   **Post-Action:**
    1.  Copy the **Fingerprint (FPR)** from the output.
    2.  Paste it into the `GPG_FPR` variable in your `.env` file.

### 2.2. Cleanup
Clear the temporary RAM disk workspace.
```bash
make cleanup
```

---

## 3. Subkey Generation

### 3.1. Import Primary Key
Import the test primary key from the USB backup into the workspace.

```bash
make import-keys USB="/path/to/your/usb"
```

### 3.2. Add Subkeys
Generate the test subkeys. They are also backed up to the USB drive.

```bash
make add-subkeys USB="/path/to/your/usb"
```

### 3.3. Cleanup
Clear the temporary workspace.
```bash
make cleanup
```

---

## 4. YubiKey Provisioning

### 4.1. Initialize YubiKey
Set the YubiKey's slots to the correct algorithms.

```bash
make setup-yubikey
```

### 4.2. Import Keys to Workspace
Import the test keys into the workspace again.

```bash
make import-keys USB="/path/to/your/usb"
```

### 4.3. Move Subkeys to YubiKey
This **irreversible** action transfers the subkeys to the YubiKey.

> **Note:** This moves keys from the temporary workspace (`$GPG_RAMDISK_DIR`) to the YubiKey. The backup on your USB drive is **not** affected.

```bash
make move-subkeys-to-card
```

### 4.4. Final Cleanup
Clear the temporary workspace. The YubiKey is now provisioned with the test keys.
```bash
make cleanup
```

---

## 5. Secure Cleanup (CRITICAL STEP)

After completing the test, you **must** securely destroy all artifacts to prevent the test keys from being used.

### 5.1. Delete USB Backup
Securely delete the `gpg_backup` directory from your test USB drive.

```bash
# Ensure you have the correct path to your USB drive
rm -rf /path/to/your/usb/gpg_backup
```

### 5.2. Reset YubiKey OpenPGP Applet
This will completely wipe the OpenPGP data from the YubiKey, returning it to a factory state. This requires the [YubiKey Manager (ykman)](https://www.yubico.com/products/yubikey-manager/) CLI tool.

> **Warning:** This action will delete all GPG keys from the YubiKey and cannot be undone.

```bash
ykman openpgp reset
```

You will be asked for confirmation. Proceed to reset the device. The test is now complete and all test materials have been destroyed.
