#!/usr/bin/expect -f

set timeout -1
set fpr [lindex $argv 0]

if {$fpr == ""} {
    puts "エラー: フィンガープリントを指定しろ。"
    exit 1
}

spawn gpg --edit-key $fpr

expect "gpg>"
send "keytocard\r"
expect "Your selection?"
send "1\r"

expect {
    "Really move the primary key?" {
        send "y\r"
        exp_continue
    }
    "gpg>" {
        send "save\r"
    }
}
expect eof