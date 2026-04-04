#!/bin/bash
: "${GPG_RAMDISK_DIR:?エラー: GPG_RAMDISK_DIR が未設定だ。}"

if [ -d "$GPG_RAMDISK_DIR" ]; then
    rm -rf "$GPG_RAMDISK_DIR"
    echo "=> RAMディスク ($GPG_RAMDISK_DIR) を完全に破棄した。"
else
    echo "=> 破棄すべきRAMディスクは存在しない。"
fi