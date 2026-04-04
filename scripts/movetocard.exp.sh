#!/usr/bin/expect -f

set timeout -1
# さっき取得したフィンガープリントを引数に渡せ
set fpr [lindex $argv 0]

if {$fpr == ""} {
    puts "エラー: フィンガープリントを引数に指定しろ。"
    exit 1
}

spawn gpg --edit-key $fpr

# 副鍵1 (Sign) を YubiKey の Signature スロット(1) へ
expect "gpg>"
send "key 1\r"
expect "gpg>"
send "keytocard\r"
expect "Your selection?"
send "1\r"

# 副鍵1の選択を解除し、副鍵2 (Encrypt) を Encryption スロット(2) へ
expect "gpg>"
send "key 1\r"
expect "gpg>"
send "key 2\r"
expect "gpg>"
send "keytocard\r"
expect "Your selection?"
send "2\r"

# 保存して終了
expect "gpg>"
send "save\r"
expect eof