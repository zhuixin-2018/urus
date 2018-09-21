#!/bin/bash
set -x
. ../../../../utils/sh-test-lib
. ../../../../utils/sys_info.sh

cd -

url=`pwd`
echo $url
random_uuid=`cat /proc/sys/kernel/random/uuid`

if [ `whoami` != 'root' ]; then
        echo "YOu must be the root to run this script" >$2
        exit 1
fi


#Check that the kernel supports KVM
ret=`dmesg|grep kvm|grep "initialized successfully"|awk '{print $7,$8}'`
if [ "$ret"x = "initialized successfully"x ];then
        print_info 0 kvm_enable
else
        print_info 1 kvm_enable
fi

#Installation package
pkgs="qemu-kvm qemu-efi libvirt-bin virtinst"
install_deps "${pkgs}"
print_info $? install-package


#Modify configuration file
LIBVIRT=/etc/libvirt/libvirtd.conf
sed -i "s/#unix_sock_group = /unix_sock_group = /g" $LIBVIRT
sed -i "s/#unix_sock_ro_perms = /unix_sock_ro_perms = /g" $LIBVIRT
sed -i "s/#unix_sock_rw_perms = /unix_sock_rw_perms = /g" $LIBVIRT
sed -i "s/#auth_unix_ro = /auth_unix_ro = /g" $LIBVIRT
sed -i "s/#auth_unix_rw = /auth_unix_rw = /g" $LIBVIRT
sed -i "s/#listen_tls = 0/listen_tls = 0/g" $LIBVIRT
sed -i "s/#listen_tcp = 1/listen_tcp = 1/g" $LIBVIRT
sed -i "s/#auth_tcp=/auth_tcp=/g" $LIBVIRT
sed -i "s/#user = /user = /g" /etc/libvirt/qemu.conf
sed -i "s/#group = /group = /g" /etc/libvirt/qemu.conf
print_info $? modify_configure


cp demo.xml domain_aarch64.xml
sed -i "s%<uuid>e06d5011-2de4-48a0-834e-72eecf7c99f0</uuid>%<uuid>${random_uuid}</uuid>%g" domain_aarch64.xml

sed -i "s%<source file='/home/dingyu/cirros-0.4.0-aarch64-disk.img'/>%<source file='${url}/cirros-0.4.0-aarch64-disk.img'/>%g" domain_aarch64.xml
print_info $? modify_xml

wget http://192.168.50.122:8083/test_dependents/cirros-0.4.0-aarch64-disk.img  
print_info $? download_img

#Start the libvirt service
service libvirtd start
print_info $? libvirtd_start

#Test whether libvirt works at the system level
virsh -c qemu:///system list
print_info $? libvirt_works

#Create virtual machines

virsh define domain_aarch64.xml
print_info $? virtual_create

virsh start domain_aarch64
print_info $? virtual_start

virsh reboot domain_aarch64
print_info $? domain_reboot

virsh list --all
print_info $? virsh_list

virsh autostart domain_aarch64
print_info $? domain_autostart

virsh autostart --disable domain_aarch64
print_info $? disable_autostart

virsh dominfo domain_aarch64
print_info $? domain_info

virsh dumpxml domain_aarch64
print_info $? dumpxml_info

virsh suspend domain_aarch64
print_info $? domain_suspend

virsh resume domain_aarch64
print_info $? domain_resume

virsh dommemstat domain_aarch64
print_info $? domain_mem

virsh vcpuinfo domain_aarch64
print_info $? vcpu_info

virsh domid domain_aarch64
print_info $? domain_id

virsh domuuid domain_aarch64
print_info $? domain_uuid

virsh domstate domain_aarch64
print_info $? domain_status

virsh domblklist domain_aarch64
print_info $? domain_blk

virsh domiflist domain_aarch64
print_info $? domain_ifconfig

virsh domcontrol domain_aarch64
print_info $? domain_control

virsh memtune domain_aarch64
print_info $? domain_memtune

virsh blkiotune domain_aarch64
print_info $? domain_blkiotune

virsh shutdown domain_aarch64
print_info $? domain_shutdown

virsh destroy domain_aarch64
print_info $? domain_destroy

virsh setmaxmem domain_aarch64 1048576
print_info $? domain_setmaxmem

virsh setmem domain_aarch64 524288 --current
print_info $? domain_setmem 

virsh setvcpus domain_aarch64 1 --current
print_info $? domain_setvcpus 

virt-clone --connect=qemu:///system -o domain_aarch64 -n domain_copy -f /var/lib/libvirt/images/domain_copy.qcow2
print_info $? domain_clone

#delete virtual machines
virsh undefine --nvram domain_aarch64
rm -rf cirros-0.4.0-aarch64-disk.img
print_info $? domain_undefine

virsh undefine --nvram domain_copy
rm -rf /var/lib/libvirt/images/domain_copy.qcow2
print_info $? delete_clone

rm -rf domain_aarch64.xml
print_info $? delete_xml

#Stop the libvirt service
service libvirtd stop
print_info $? libvirtd_stop

