#!/bin/bash

if [ ! $1 ]; then
    echo Usage: $0 VER [zero]
    echo '  Where VER is the 4-digit version number of MAME to update (for example: 0224).'
    echo '  Where zero overwrite the free space with zeros to optimize compression.'
    exit
fi

# IMGNAME=rpi4b.raspios.mame-$1.appliance.img
IMGNAME=rpi4b.raspios.mame-$1.appliance.fe-edition.img

if [ ! -f ~/$IMGNAME ]; then
    echo $IMGNAME does not exist!
    exit
fi

if [ -f $IMGNAME.gz ]; then
    rm $IMGNAME.gz
fi

# Écrasement de l'espace libre de rootfs avec des zéros
if [ "$2" = "zero" ]; then
    ./mount-rootfs.rpi4b.raspios.mame.sh $1 zero
fi

gzip -9 -k $IMGNAME

ls -la $IMGNAME $IMGNAME.gz
