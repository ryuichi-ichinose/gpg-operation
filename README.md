# GPG & YubiKey Operation Guide

> **IMPORTANT DISCLAIMER**
>
> These scripts are powerful tools that manage sensitive cryptographic keys. Before proceeding, you must:
>
> 1.  **Understand the Process:** Have a solid understanding of GPG and YubiKey operations. Review these scripts carefully to understand what they do.
> 2.  **Test Thoroughly:** Follow the procedures outlined in `device_test.md` to ensure your hardware and environment are compatible before managing real keys.
> 3.  **Check OS Compatibility:** These scripts are currently designed for and tested on **Fedora Linux**. For other operating systems, you will need to modify the `scdaemon` path as noted in the `#TODO` comments within the scripts.
>
> Use these scripts at your own risk.

This repository provides a set of scripts to automate the generation, management, and migration of GPG keys to a YubiKey.

## -1. System Dependencies

Before using these scripts, you need to install several dependencies. They are divided into "Required" (for script automation) and "Recommended" (for diagnostics and manual operations).

### Required Packages
These packages are essential for the scripts in this repository to run correctly. `yubikey-manager` is included here as it's vital for managing the YubiKey itself.

**On Fedora / RHEL-based systems:**
```bash
sudo dnf install -y gnupg2 pcsc-lite yubikey-manager paperkey qrencode expect
```

**On Debian / Ubuntu-based systems:**
```bash
sudo apt-get update
sudo apt-get install -y gnupg2 pcscd yubikey-manager paperkey qrencode expect
```

### Recommended Tools
These tools are not directly called by the scripts but are highly recommended for diagnostics and manual parts of the workflow.

**On Fedora / RHEL-based systems:**
```bash
sudo dnf install -y pcsc-tools zbar
```

**On Debian / Ubuntu-based systems:**
```bash
sudo apt-get install -y pcsc-tools zbar-tools
```

---
**After installation**, you must enable and start the `pcscd` service, which allows communication with the YubiKey:
```bash
sudo systemctl enable --now pcscd.socket
```

<details>
<summary><strong>List of Packages and Their Purpose</strong></summary>

| Package           | Role & Rationale                                                                 |
|-------------------|----------------------------------------------------------------------------------|
| `gnupg2`          | **Required.** The core functionality of the GPG encryption suite.                |
| `pcscd`           | **Required.** A low-level daemon for communicating with smart cards.             |
| `yubikey-manager` | **Required.** The `ykman` utility for configuring and managing the YubiKey.      |
| `paperkey`        | **Required.** Extracts and restores secret keys for paper backups.               |
| `qrencode`        | **Required.** Converts text output into a QR code image.                         |
| `expect`          | **Required.** A tool for automating `gpg`'s interactive prompts.                 |
| `pcsc-tools`      | **Recommended.** Provides `pcsc_scan` for checking smart card reader status.     |
| `zbar-tools`      | **Recommended.** Provides `zbarcam` for reading QR codes from a webcam.          |

</details>

---

## 0. Prerequisites

### 0.1. Environment Variables
First, create a `.env` file in the project root and set the following variables.

```bash
# Example .env file

# Basic GPG Key Information
export GPG_KEY_NAME="your name"
export GPG_KEY_EMAIL="your email address"
# Set this to the fingerprint displayed after primary key generation
export GPG_FPR=""

# SSH Key Information
export SSH_KEY_EMAIL="your email address"

# Temporary working directory (RAM disk is recommended)
export GPG_RAMDISK_DIR="/dev/shm/gpg_workspace"

# OS-Specific Path for GPG Smart Card Daemon
# This path is critical for the scripts to function correctly.
# See the "OS-Specific Notes" section below for details on how to find this path.
export GPG_SCDAEMON_PATH="/usr/libexec/scdaemon" # Fedora default
```

### 0.2. OS-Specific Notes: Finding Your `scdaemon` Path

The `GPG_SCDAEMON_PATH` environment variable tells the scripts where to find the GPG smart card daemon (`scdaemon`), which is essential for communicating with the YubiKey. The location of this daemon varies across different Linux distributions.

**Currently, these scripts have only been verified to work on Fedora Linux with the default path `/usr/libexec/scdaemon`.**

To find the correct path on your system, the most reliable method is to use the `find` command:
```bash
# Find the scdaemon path (might take a moment)
find /usr -name scdaemon 2>/dev/null
```
Once you find the path, update the `GPG_SCDAEMON_PATH` variable in your `.env` file accordingly.

**We welcome contributions and feedback!** If you have successfully run these scripts on other distributions (e.g., Debian, Ubuntu, Arch Linux), please consider opening an issue or pull request to share your findings and help us improve compatibility.

---

## 1. Initial Setup (First Time Only)

### 1.1. Generate GPG Key Pair (Primary Key + Subkeys)

1.  **Generate Primary Key**
    - This is the master key, holding only the `certify` capability.

    ```bash
    make generate-primary-key USB="/path/to/your/usb"
    ```
    > **Important:** After this command, copy the **fingerprint (FPR)** displayed on the screen and set it as the value for `GPG_FPR` in your `.env` file.

2.  **Generate Subkeys**
    - These are the daily-use keys with `sign`, `encrypt`, and `authenticate` capabilities.
    - The **expiration is set to 1 year**.

    ```bash
    make add-subkeys USB="/path/to/your/usb"
    ```

3.  **Cleanup Working Directory**
    - Deletes temporary files from the RAM disk.

    ```bash
    make cleanup
    ```

### 1.2. Initialize YubiKey

- Sets the YubiKey's key slots to use `ed25519` and `cv25519` (Curve25519), which are recommended for GPG.

```bash
make setup-yubikey
```

---

## 2. YubiKey Migration

### 2.1. Move Subkeys to YubiKey

1.  **Import GPG Keys**
    - Loads keys from the backup USB into the temporary RAM disk.

    ```bash
    make import-keys USB="/path/to/your/usb"
    ```

2.  **Move Subkeys to YubiKey**
    > **Warning:** This operation is **irreversible**. Once subkeys are moved to the YubiKey, they cannot be extracted.

    ```bash
    make move-subkeys-to-card
    ```
    > **Note:** This operation moves the keys to the card for daily use, replacing the local copies with stubs. However, the original secret subkey file (`subkeys_secret.asc`) is **not** deleted from your backup USB. This file serves as your crucial backup. Ensure your backup USB is stored in a physically secure, offline location.


3.  **Cleanup Working Directory**

    ```bash
    make cleanup
    ```

### 2.2. Configure Host PC for Public Key

- Configures your daily-use computer to use the GPG key associated with your YubiKey.

1.  **Import Public Key and Stubs**
    - This allows the PC to recognize that the secret keys are located on the YubiKey.

    ```bash
    make import-keys-to-host USB="/path/to/your/usb"
    ```

2.  **Cleanup Working Directory**

    ```bash
    make cleanup
    ```

3.  **Export Public Key**
    - Copies the public key to your clipboard for uploading to GitHub or a key server.

    ```bash
    gpg --armor --export $GPG_FPR | xclip -sel clip
    ```

---

## 3. Periodic Maintenance (Yearly Cycle)

### 3.1. Renewing Expiration Dates

1.  **Import GPG Keys**

    ```bash
    make import-keys USB="/path/to/your/usb"
    ```

2.  **Extend Expiration Date (Guided Interactive Mode)**
    - An interactive GPG prompt will start.
    - Follow the on-screen instructions to set the new expiration date for each key (primary and subkeys) individually.

    ```bash
    make extend-key-limit USB="/path/to/your/usb"
    ```

3.  **Cleanup Working Directory**

    ```bash
    make cleanup
    ```

4.  **Apply New Public Key to Host**

    ```bash
    make import-keys-to-host USB="/path/to/your/usb"
    ```

5.  **Redistribute Public Key**
    - Re-upload the updated public key to services like GitHub or a key server.

---

## 4. Ultimate Recovery (QR Code)

- Restores the primary key from a physical paper backup.

1.  **Scan the QR Code**
    - Use a tool like `zbar` to scan the QR code and get the base64-encoded string.

2.  **Restore the Key**

    ```bash
    make restore-from-qr USB="/path/to/your/usb" QR_DATA="<scanned_string>"
    ```

---

## 5. SSH (FIDO2) Management

The secret key for a FIDO2/U2F-backed SSH key (e.g., `-t ed25519-sk`) is generated **inside the YubiKey's secure element** and **cannot be exported**. This design is what makes it highly secure.

However, this also means it **cannot be backed up** in the traditional sense. If your YubiKey is lost or damaged, the secret key is gone forever.

What you *can* save is the **key handle**. This is a public reference file that allows your computer to identify and communicate with the private key stored on the YubiKey. Saving this handle enables you to use the same YubiKey across multiple computers without re-registering it everywhere.

### 5.1. Generating the Key and Saving the Handle

1.  **Generate SSH Key on YubiKey**
    - This command generates a new FIDO2/U2F (`sk`) type SSH key. The private key is created and stored securely inside the YubiKey.
    - It saves the public key (`.pub`) and the corresponding key handle (a small file, **not** the private key) to your designated USB drive.

    ```bash
    make generate-ssh-key USB="/path/to/your/usb"
    ```
    > **Reminder:** The `id_..._sk` file saved to your USB is **not a secret key backup**. It is a public reference needed to use the key on the YubiKey.

2.  **Using the SSH Key on a New Computer**
    - To use your YubiKey's SSH key on a new machine, you must load the key handle you previously saved.
    - The `ssh-keygen -K` command will find the key files on the USB drive and load them into your local SSH configuration, allowing you to use the key for authentication.

    ```bash
    ssh-keygen -K
    ```
---

## 6. Switching YubiKeys

This procedure outlines how to switch the GPG key reference on a PC to a new YubiKey.

1.  **Delete Old YubiKey Stubs (Reference Info)**
    - The `.key` files in `~/.gnupg/private-keys-v1.d/` are not the secret keys themselves but rather pointers indicating which YubiKey holds the secret key. Delete these files.
    > **Note:** This operation is safe because the actual secret keys are stored securely on your YubiKey and your backup USB.

    ```bash
    rm ~/.gnupg/private-keys-v1.d/*.key
    ```

2.  **Restart GPG Daemon and Recognize New YubiKey**
    - With the new YubiKey plugged in, restart the GPG processes.

    ```bash
    gpgconf --kill all
    ```
    - Run `gpg --card-status` to confirm that the new YubiKey is recognized correctly.

    ```bash
    gpg --card-status
    ```
    GPG will now recognize the new YubiKey as the location for the secret keys.

---
## Appendix: `gpg_backup` Directory Structure

A `gpg_backup` directory will be created on your backup USB, containing the following files:

```
gpg_backup/
├── primary-secret-qr.png
├── primary_secret.asc
├── public.asc
├── revoke.asc
└── subkeys_secret.asc
```

- **`primary_secret.asc`**: The most critical file. This is your primary secret key. Store it with extreme care.
- **`subkeys_secret.asc`**: The secret keys for your daily-use subkeys.
- **`public.asc`**: Your public key (primary + subkeys), which you can distribute to others.
- **`revoke.asc`**: The revocation certificate, used to invalidate your key if it is ever compromised.
- **`primary-secret-qr.png`**: A QR code version of `primary_secret.asc`. This serves as an ultimate offline backup.
