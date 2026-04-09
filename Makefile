# Makefile for GPG/SSH Key Management Workflow
#
# This Makefile simplifies the execution of the GPG/SSH key management scripts.
# Before using, please create a `.env` file with your details.
# See README.md for more information.

# Default USB mount point. Can be overridden from the command line.
# Example: make generate-primary-key USB="/mnt/my usb"
USB ?= /mnt/usb_master

# --- Pre-flight Checks ---
SHELL := /bin/bash
# Stop if .env file is missing for most targets.
ALLOWED_WITHOUT_ENV := help setup-permissions
IS_ENV_REQUIRED := $(if $(filter $(firstword $(MAKECMDGOALS)),$(ALLOWED_WITHOUT_ENV)),,true)

ifeq ($(IS_ENV_REQUIRED),true)
    ifneq ($(wildcard .env),)
        -include .env
        export
    else
        $(error .env file not found. Please create it first. See README.md)
    endif
endif


.PHONY: all help setup-yubikey setup-permissions generate-primary-key import-keys add-subkeys move-subkeys-to-card cleanup generate-ssh-key backup-primary-key sync-backup restore-from-qr

all: help

help:
	@echo "Usage: make [target] [VARIABLE=value]"
	@echo ""
	@echo "Examples:"
	@echo '  make generate-primary-key USB="/run/media/user/My USB"'
	@echo '  make sync-backup SRC_USB="/mnt/master" DST_USB="/mnt/replica"'
	@echo '  make restore-from-qr USB="/mnt/new_usb" QR_DATA="Base64String..."'
	@echo ""
	@echo "Targets:"
	@echo "  help                     Show this help message."
	@echo "  setup-yubikey            Run the YubiKey key attribute setup script."
	@echo "  setup-permissions        Set execute permissions for all scripts."
	@echo "  ---"
	@echo "  generate-primary-key     Generate GPG primary key and back it up. Needs 'USB'."
	@echo "  import-keys              Import keys from master USB to RAM disk. Needs 'USB'."
	@echo "  add-subkeys              Generate subkeys and back them up. Needs 'USB'."
	@echo "  move-subkeys-to-card     Move subkeys to the YubiKey."
	@echo "  cleanup                  Clean up the RAM disk environment."
	@echo "  import-keys-to-host      Import keys from master USB to host '.gnupg'. Needs 'USB'."
	@echo "  ---"
	@echo "  generate-ssh-key         Generate a new SSH key on the YubiKey. Needs 'USB'."
	@echo "  ---"
	@echo "  backup-primary-key       Create a new backup of the primary key. Needs 'USB' (path to new backup)."
	@echo "  extend-key-limit         Extend key limit one year. Needs 'USB'."
	@echo "  restore-from-qr          Restore primary key from QR code and backup to 'USB'. Optionally set 'QR_DATA'."

# --- Setup ---
setup-yubikey:
	@echo "Setting up YubiKey attributes..."
	@. .env && ./scripts/gpg/setup_yubikey.sh

setup-permissions:
	@chmod +x scripts/gpg/*.sh scripts/ssh/*.sh
	@echo "Scripts are now executable."

# --- GPG Key Lifecycle ---
# Use '.' (dot) instead of 'source' for better portability.
generate-primary-key:
	@echo "Generating primary key on \"$(USB)\"..."
	@. .env && ./scripts/gpg/generate_primary_key.sh "$(USB)"

import-keys:
	@echo "Importing keys from \"$(USB)\"..."
	@. .env && ./scripts/gpg/import_keys.sh "$(USB)"

add-subkeys:
	@echo "Adding subkeys and backing up to \"$(USB)\"..."
	@. .env && ./scripts/gpg/add_subkeys.sh "$(USB)"

move-subkeys-to-card:
	@echo "Moving subkeys to YubiKey... Please follow the prompts."
	@. .env && ./scripts/gpg/movetocard_subkeys.sh

cleanup:
	@echo "Cleaning up RAM disk..."
	@. .env && ./scripts/gpg/cleanup_ramdisk.sh

import-keys-to-host:
	@echo "Importing keys to host(.gnupg) from \"$(USB)\"..."
	@. .env && ./scripts/gpg/import_public_key_to_host.sh "$(USB)"

# --- SSH Key ---
generate-ssh-key:
	@echo "Generating SSH key on YubiKey, backup to \"$(USB)\"..."
	@. .env && ./scripts/ssh/generate_ssh_sk.sh "$(USB)"

# --- Maintenance & Recovery ---
backup-primary-key:
	@echo "Backing up primary key to \"$(USB)\"..."
	@. .env && ./scripts/gpg/backup_primary_key.sh "$(USB)"

extend-key-limit:
	@echo "Extend GPG keys for 1 year..."
	@./scripts/gpg/extend_key_limit.sh "$(USB)"

restore-from-qr:
	@echo "Restoring primary key from QR code to \"$(USB)\"..."
	@. .env && ./scripts/gpg/restore_and_backup.sh "$(USB)" "$(QR_DATA)"
