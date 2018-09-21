#!/bin/bash
#gtest is Google's Unit test tool
# Author: mahongxin <hongxin_228@163.com>
set -x
cd ../../../../utils
. ./sys_info.sh
. ./sh-test-lib
cd -

#Test user id
if [ `whoami` != 'root' ]; then
    echo " You must be the superuser to run this script" >&2
    exit 1
fi
#distro=`cat /etc/redhat-release | cut -b 1-6`
case $distro in
    "centos"|"fedora"|"opensuse")
        pkgs="gcc gcc-c++ git make"
        install_deps "${pkgs}"
       # git clone https://github.com/google/googletest.git
       # print_info $? install-gtest
        ;;
    "ubuntu"|"debian")
	pkgs="gcc g++ git make"
	install_deps "${pkgs}"
	print_info $? install-deps
        ;;

esac
git clone https://github.com/google/googletest.git
print_info $? install-gtest
cp Makefile googletest/googletest/samples
cd googletest/googletest/samples
make
./run_test
print_info $? compile-gtest
touch sqrt.h
chmod 777 sqrt.h
touch sqrt.cpp
chmod 777 sqrt.cpp
touch sqrt_unittest.cpp
chmod 777 sqrt_unittest.cpp
cat << EOF > ./sqrt.h
#ifndef _SQRT_H_
#define _SQRT_H_

int sqrt(int x);
#endif //_SQRT_H_
EOF

cat << EOF > ./sqrt.cpp
#include "sqrt.h"
int sqrt(int x) {
    if(x<=0) return 0;
    if(x==1) return 1;

    int small=0;
    int large=x;
    int temp=x/2;

    while(small<large){
        int a = x/temp;
        int b = x/(temp+1);

        if (a==temp) return a;
        if (b==temp+1) return b;

        if(temp<a && temp+1>b){
            return temp;
        }
        else if(temp<a && temp+1<b){
            small=temp+1;
            temp = (small+large)/2;
        }else {
            large = temp;
            temp = (small+large)/2;
        }
    }
    return -1;
}
EOF

cat <<EOF > ./sqrt_unittest.cpp

#include "sqrt.h"
#include "gtest/gtest.h"

TEST(SQRTTest,Zero){
    EXPECT_EQ(0,sqrt(0));
}

TEST(SQRTTest,Positive){
    EXPECT_EQ(100,sqrt(10000));
    EXPECT_EQ(1000,sqrt(1000009));
    EXPECT_EQ(99,sqrt(9810));
}

TEST(SQRTTest,Negative){
    int i=-1;
    EXPECT_EQ(0,sqrt(i));
}
EOF
make clean
make
print_info $? compile-cpp
./run_test
print_info $? run-cpp
file1="./sqrt.o"
file2="./sqrt_unittest.o"
TCID="gtest-testing"
if [ -f "$file1" ] && [ -f "$file2" ];then
    lava-test-case $TCID --result pass
else
    lava-test-case $TCID --result fail
fi
case $distro in
    "centos"|"fedora"|"opensuse")
        #yum remove gcc gcc-c++ git make  -y
        remove_deps "${pkgs}"
        print_info $? remove-pkgs
        ;;
    "ubuntu"|"debian")
	remove_deps "${pkgs}"
	print_info $? remove-pkgs
esac
