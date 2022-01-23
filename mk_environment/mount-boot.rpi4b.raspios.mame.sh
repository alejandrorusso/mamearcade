#!/bin/sh

if [ ! $1 ]; then
    echo Usage: $0 VER
    echo '  Where VER is the 4-digit version number of MAME image file (for example: 0224).'
    exit
fi

# IMGNAME=rpi4b.raspios.mame-$1.appliance.img
IMGNAME=rpi4b.raspios.mame-$1.appliance.fe-edition.img

if [ ! -f ~/$IMGNAME ]; then
    echo $IMGNAME does not exist!
    exit
fi

if [ ! -d /tmp/boot.img ]; then
    sudo mkdir /tmp/boot.img
fi
sudo mount -t vfat -o loop,rw,sync,offset=4194304 ~/$IMGNAME /tmp/boot.img
cd /tmp/boot.img
echo -------------------------------------------
$SHELL
echo -------------------------------------------
echo Unmounting image.....
cd ~
sudo umount /tmp/boot.img
echo Done!
