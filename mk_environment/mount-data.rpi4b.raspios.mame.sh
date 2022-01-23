#!/bin/sh

if [ ! $1 ]; then
    echo Usage: $0 VER
    echo '  Where VER is the 4-digit version number of MAME image file (for example: 0224).'
    exit
fi

#IMGNAME=rpi4b.raspios.mame-$1.appliance.img
IMGNAME=rpi4b.raspios.mame-$1.appliance.fe-edition.img

if [ ! -f ~/$IMGNAME ]; then
    echo $IMGNAME does not exist!
    exit
fi

if [ ! -d /tmp/data.img ]; then
    sudo mkdir /tmp/data.img
fi
sudo mount -o loop,rw,sync,offset=13157531648 ~/$IMGNAME /tmp/data.img
cd /tmp/data.img

if [ "$2" = "zero" ]; then
    echo Overwriting free space with zeros...
    dd if=/dev/zero of=zeros bs=8M status=progress
    rm zeros
else
    echo -------------------------------------------
    $SHELL
    echo -------------------------------------------
fi

echo Unmounting image.....
cd ~
sudo umount /tmp/data.img
echo Done!
