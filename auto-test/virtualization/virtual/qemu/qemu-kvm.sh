#!/bin/bash

set -x

cd ../../../../utils
. ./sys_info.sh
. ./sh-test-lib
cd -

#modify by liucaili 2017-06-08
#IMAGE='Image_D02'
IMAGE='Image'
ROOTFS='mini-rootfs.cpio.gz'
HOME_PATH=$HOME
CUR_PATH=$PWD
DISK_NAME=${distro}.img

download_url=$1

if [ ! -e ${CUR_PATH}/${IMAGE} ]; then
    download_file ${download_url}/${IMAGE}
fi

if [ ! -e ${CUR_PATH}/${ROOTFS} ]; then
    download_file ${download_url}/${ROOTFS}
fi

if [[ -e ${CUR_PATH}/${IMAGE} && -e ${CUR_PATH}/${ROOTFS} ]]; then
   lava-test-case image_or_rootfs_exist --result pass
else
   echo '${IMAGE} or ${ROOTFS} not exist'
   lava-test-case image_or_rootfs_exist --result fail
   exit 0
fi

# compail and install 
pkgs="expect wget qemu qemu-kvm gcc"
install_deps "${pkgs}"
case "${distro}" in
	debian|ubuntu)
		pkgs="libvirt-bin zlib1g-dev libperl-dev libgtk2.0-dev libfdt-dev bridge-utils"
		install_deps "${pkgs}"
	;;
	centos|fedora)
		yum remove yum-plugin-priorities.noarch -y
		pkgs="kvm virt-manager virt-install xauth qemu-img libvirt libvirt-python libvirt-client glib2-devel"
		install_deps "${pkgs}"
	;;
	*)
		error_msg "Unsupported distribution!"
esac
print_info $? qemu-install

qemu-system-aarch64 --help
if [ $? -ne 0 ]; then
    QEMU_VER=qemu-2.6.0.tar.bz2
    download_file http://wiki.qemu-project.org/download/${QEMU_VER}
    tar xf ${QEMU_VER}
    cd ${QEMU_VER%%.tar.bz2}
    ./configure --target-list=aarch64-softmmu
    make -j16
    make install
    cd -

    qemu-system-aarch64 --help
fi
print_info $? qemu-system-aarch64-help

chmod a+x ${CUR_PATH}/qemu-load-kvm.sh

# start qemu 
# add distro as parameter  20180408 liucaili
${CUR_PATH}/qemu-load-kvm.sh $IMAGE $ROOTFS $distro
if [ $? -ne 0 ]; then
    echo 'qemu system load fail'
   # lava-test-case qemu-system-load --result fail
    exit 0
else
    lava-test-case qemu-system-load --result pass
fi

# create image , like virtual matchine disk file 
qemu-img create -f qcow2 $DISK_NAME 10G
if [ $? -ne 0 ]; then
    echo 'qemu-img create fail'
    lava-test-case qemu-img-create --result fail
    exit 0
else
   lava-test-case qemu-img-create --result pass
fi

# mount network block device moduler
modprobe nbd max_part=16
if [ $? -ne 0 ];then
    echo 'modprobe nbd fail'
    lava-test-case modprob-nbd --result fail
    exit 0
else
    lava-test-case modprobe-nbd --result pass
fi

# install os
qemu-nbd -c /dev/nbd0 $DISK_NAME
chmod a+x ${CUR_PATH}/qemu-create-partition.sh
${CUR_PATH}/qemu-create-partition.sh
if [ $? -ne 0 ];then
    echo 'create nbd0 partition fail'
    lava-test-case create-partition --result fail
    exit 0
else
    #nbd_p1=$(fdisk /dev/nbd0 -l | grep -w 'nbd0p1')
	#modify by liucaili 2017-06-09
    nbd_p1=$(fdisk /dev/nbd0 -l | grep -w 'Linux')
    if [ "$nbd_p1"x = ""x ] ; then
        lava-test-case create-partition --result fail
    else
        lava-test-case create-partition --result pass
    fi
fi

# formate virtual disk 
mkfs.ext4 /dev/nbd0p1
if [ $? -ne 0 ]
then
    echo 'mkfs.ext4 nbd0p1 fail'
    lava-test-case mkfs.ext4-nbd0p1 --result fail
    exit 0
else
    lava-test-case mkfs.ext4-nbd0p1 --result pass
fi

mkdir -p /mnt/image
mount /dev/nbd0p1 /mnt/image/
if [ $? -ne 0 ];then
    echo 'mount image fail'
    lava-test-case mount-image --result fail
    exit 0
else
    lava-test-case mount-image --result pass
fi

# put rootfs write to virtual disk 
cd /mnt/image
zcat ${CUR_PATH}/${ROOTFS} | cpio -dim
if [ $? -ne 0 ]
then
    echo 'tar file system fail'
    lava-test-case tar-file-system --result fail
    exit 0
else
    lava-test-case tar-file-system --result pass
fi
cd ${CUR_PATH}

umount /mnt/image
if [ $? -ne 0 ]
then
    echo 'umount image fail'
    lava-test-case umount-image --result fail
    exit 0
else
    lava-test-case umount-image --result pass
fi

qemu-nbd -d /dev/nbd0
if [ $? -ne 0 ];then
    echo 'qemu-nbd fail'
    lava-test-case qemu-nbd --result fail
    exit 0
else
    lava-test-case qemu-nbd --result pass
fi

# start virtual os 
chmod a+x qemu-start-kvm.sh
${CUR_PATH}/qemu-start-kvm.sh  $IMAGE  $DISK_NAME
if [ $? -ne 0 ];then
    echo 'qemu-start-from-img fail'
    lava-test-case qemu-start-from-img --result fail
    exit 0
else
    lava-test-case qemu-start-from-img --result pass
fi
