#!/bin/sh
# Copyright (C) 2017-8-29, Linaro Limited.
#qperf is a tool for testing bandwidth and latency
# Author: mahongxin <hongxin_228@163.com>

set -x

cd ../../../../utils
    . ./sys_info.sh
cd -

# Test user id
if [ `whoami` != 'root' ] ; then
    echo "You must be the superuser to run this script" >&2
    exit 1
fi
#distro=`cat /etc/redhat-release | cut -b 1-6`
case $distro in
    "centos")
        yum install wrk.aarch64 -y
        print_info $? install-wrk
         ;;
esac
#distro=`cat /etc/redhat-release |cut -b 1-6`
#Test ' wrk server'
TCID="wrk-test"
wrk -c 1 -t 1 -d 1 http://www.baidu.com  2>&1 | tee wrk.log
print_info $? wrk-test
str=`grep -Po "Socket errors" wrk.log`
if [ "$str" != "" ] ; then
    lava-test-case $TCID --result fail
else
    lava-test-case $TCID --result pass
fi
rm wrk.log
case $distro in
    "centos")
        yum remove wrk.aarch64 -y
        print_info $? remove-wrk
        ;;
esac
