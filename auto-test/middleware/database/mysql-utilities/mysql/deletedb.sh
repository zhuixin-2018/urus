#!/bin/bash
#delete database test


mysql -uroot -proot -e "drop database $1"


if false;then
set dbname [lindex $argv 0]

EXPECT=$(which expect)
$EXPECT << EOF | tee out.log
set timeout 500
spawn mysql -u root -p
expect "password:"
send "root\r"
expect "mysql>"
send "drop database $dbname;\r"
expect "OK"
send "exit\r"
expect eof
EOF
fi 
