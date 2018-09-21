#!/bin/bash
cd ../../../../utils
    . ./sys_info.sh
    . ./sh-test-lib
cd -
case $distro in
    "centos"|"fedora"|"opensuse")
	#yum install net-tools -y
	pkgs="net-tools"
	install_deps "$pkgs"
        ;;
        ubuntu|debian)
        #apt-get install net-tools -y
	pkgs="net-tools"
        install_deps "$pkgs" 
esac
	
inet=`ip link|grep "state UP"|awk '{print $2}'|head -1|sed 's/0:/9/g'`
echo $inet

ETG=`ethtool -g $inet`
echo $ETG

if [ '$ETG|grep "No such device"' != "" ]; then
	lava-test-case "fault_tolerance_test" --result pass
else
	lava-test-case "fault_tolerance_test" --result fail
fi


