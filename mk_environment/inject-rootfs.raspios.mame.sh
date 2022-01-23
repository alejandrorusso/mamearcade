#!/bin/bash

# Script pour extraire la partition 'rootfs' de la carte micro-SD et l'injecter dans le fichier-image
# pour pouvoir le publier en ligne.

if [ ! $1 ]; then
    echo Usage: $0 VER
    echo '  Where VER is the 4-digit version number of the MAME image file (for example: 0224).'
    exit
fi

IMGFILE=rpi4b.raspios.mame-$1.appliance.fe-edition.img
SDDEVICE=/dev/sdb

if [ ! -f ~/$IMGFILE ]; then
    echo $IMGFILE does not exist!
    exit
fi

echo INFO: Block size de ${SDDEVICE}1 = $(lsblk ${SDDEVICE}1 -nt | awk '{ print $6 }') octets.
echo INFO: Block size de ${SDDEVICE}2 = $(lsblk ${SDDEVICE}1 -nt | awk '{ print $6 }') octets.

# Démontage de la partition, si déjà montée
# if [ $(findmnt -n $PART | awk '{print $1}') = '/media/bbegin/rootfs' ]; then
#     sudo umount $PART
# fi

echo Démontage des partitions de la carte micro-SD...
sudo umount ${SDDEVICE}1
sudo umount ${SDDEVICE}2

# Extraction de la partition boot
sudo dd if=${SDDEVICE}1 of=boot.img status=progress bs=1M
# Extraction de la partition rootfs
sudo dd if=${SDDEVICE}2 of=rootfs.img status=progress bs=1M

# Montage du disque virtuel pour présenter les partitions sous /dev/mapper
sudo kpartx -av $IMGFILE
ls -la /dev/mapper

# Écriture de boot et rootfs vers le disque virtuel...
echo Écriture de boot.img vers le disque virtuel...
sudo dd if=boot.img   of=/dev/mapper/loop0p1 status=progress bs=1M
echo Écriture de rootfs.img vers le disque virtuel...
sudo dd if=rootfs.img of=/dev/mapper/loop0p2 status=progress bs=1M

# Retrait du disque virtuel
sync
sudo kpartx -dv $IMGFILE

sudo rm boot.img
sudo rm rootfs.img

echo Opération complétée !
ls -la $IMGFILE
