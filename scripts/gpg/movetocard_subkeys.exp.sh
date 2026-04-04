#!/usr/bin/expect -f

set timeout -1
set fpr [lindex $argv 0]

if {$fpr == ""} {
    puts "エラー: フィンガープリントを指定しろ。"
    exit 1
}

spawn gpg --edit-key $fpr

expect "gpg>"
send "key 1\r"
expect "gpg>"
send "keytocard\r"
expect "Your selection?"
send "1\r"

expect "gpg>"
send "key 1\r"
expect "gpg>"
send "key 2\r"
expect "gpg>"
send "keytocard\r"
expect "Your selection?"
send "2\r"

expect "gpg>"
send "save\r"
expect eof