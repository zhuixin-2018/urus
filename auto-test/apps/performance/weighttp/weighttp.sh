#!/bin/bash
# Copyright (C) 2017-8-29, Linaro Limited.
# Small tool to benchmark webservers
# Author: mahongxin <hongxin_228@163.com>

set -x

cd ../../../../utils
    . ./sys_info.sh
    . ./sh-test-lib
cd -

# Test user id
if [ `whoami` != 'root' ] ; then
    echo "You must be the superuser to run this script" >&2
    exit 1
fi
#distro=`cat /etc/redhat-release | cut -b 1-6`
pkgs="gcc wget tar make"
install_deps "$pkgs"

#install libev-3.7
wget http://192.168.50.122:8083/test_dependents/libev-3.7.tar.gz
    print_info $? get-libev
tar -zxvf libev-3.7.tar.gz
    print_info $? tar-libev
cd libev-3.7
./configure --build=arm-linux
make
make install

#install weighttp
wget http://192.168.50.122:8083/test_dependents/weighttp-master.tar.gz
    print_info $? wget-weighttp
tar -zxvf weighttp-master.tar.gz
    print_info $? tar-weighttp
cd weighttp-master
echo "/usr/local/lib" >> /etc/ld.so.conf
/sbin/ldconfig
./waf configure
./waf build
./waf install
    print_info $? install-weighttp

#Test ' weighttp server'
TCID="weighttp-test"
weighttp -n 1 -k http://192.168.1.107  2>&1 | tee weighttp.log
print_info $? test-weighttp
str=`grep -Po "0 failed" weighttp.log`
if [ "$str" != "" ] ; then
    lava-test-case $TCID --result pass
else
    lava-test-case $TCID1 --result fail
fi

rm weighttp.log
pkill weighttp

