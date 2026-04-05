# 1. PCに残っている古い道しるべ（スタブ）を全削除する
# （※実体はYubiKeyやUSBにあるので消しても全く問題ない）
rm ~/.gnupg/private-keys-v1.d/*.key

# 2. 新しいYubiKeyを挿した状態で、GPGデーモンを再起動して認識させる
gpgconf --kill all
gpg --card-status