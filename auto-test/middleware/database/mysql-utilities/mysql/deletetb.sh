#!/bin/bash
#delete database test



mysql -uroot -proot -e "use test ;drop database $1"





#if false ;then
#EXPECT=$(which expect)
#$EXPECT << EOF | tee out.log
#set timeout 500
#spawn mysql -u root -p
#expect "password:"
#send "root\r"
#expect "mysql>"
#send "use test;\r"
#expect "OK"
#send "drop table case_tbl;\r"
#expect "OK"
#send "drop table alter_tbl;\r"
#expect "OK"
#send "drop table author_tbl;\r"
#expect "OK"
#send "drop table case_test;\r"
#expect "OK"
#send "show tables;\r"
#expect "Empty"
#send "exit\r"
#expect eof
#EOF
#fi 
