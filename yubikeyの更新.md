# 1. RAMディスクを掃除して、USBからマスター鍵一式をロードする
make cleanup
make import-keys USB="your usb path"

# 2. 有効期限をさらに1年（1y）延長する
# (内部で expect スクリプトが走り、主鍵と全副鍵の期限を更新する)
extend-key-limit USB="your usb path"

# 3. 【重要】更新された「新しい公開鍵」をホストPCに反映させる
# 期限延長の情報は公開鍵に含まれるため、これをやらないと期限切れのままだ
make import-keys-to-host USB="your usb path"

# 4. 【重要】GitHub / GitLab 等に新しい公開鍵を登録し直す
# 古い公開鍵を削除し、USBの gpg_backup/public.asc を再度アップロードしろ
gpg --armor --export $GPG_FPR | xclip -sel clip

# 5. 後片付け
make cleanup