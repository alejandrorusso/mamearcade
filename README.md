# Building a MAME Arcade

I have dreamed about building an arcade machine for some months already. I knew
the amazing [MAME project](https://www.mamedev.org/) -- responsible to emulate
most of the hardware found in old-school arcade machines -- and I wanted an
embedded system that *just runs that*.

![ MAME Appliance Project !](https://raw.githubusercontent.com/alejandrorusso/mamearcade/main/map.jpeg)

# Status-quo
Looking around, I found great platforms like
[RetroPi](https://retropie.org.uk/), [Lakka](https://www.lakka.tv/), and
[Recallbox](https://www.recalbox.com/). However, they target emulating many
consoles (e.g., NES, SNES, Sega Megadrive, etc.) as well as arcade games via
MAME. Unfortunately, the MAME version that they provide is rather old, for
example, from 2006! I like the idea of just running MAME in my Raspberry Pi.

# The MAME Appliance Project (MAP)
Luckily, I found that I was not alone! I found [the MAME appliance
project](https://gist-github-com.translate.goog/sonicprod/f5a7bb10fb9ed1cc5124766831e120c4?_x_tr_sl=fr&_x_tr_tl=en&_x_tr_hl=fr)
that addresses this problem. It takes the Debian-based [Raspbian
OS](https://www.raspbian.org/) and sets it up in a way that you can have your
Raspberry Pi up to date with the latest version of MAME. The project is also set
up to be minimalist in the amount of resources that it uses, e.g., it does not
utilize X11.

# Extensions

After studying the project for some time. I introduced some modifications to fit
my needs.

## No need to decide between arcademode and servicemode

The MAP works in two modes: `servicemode` and `arcademode`. Service mode enables
arcade maintainers to perform activities like login into the system via SSH or a
terminal, transfer files, etc. In contrast, arcade mode is dedicated to dedicate
all the resources to play games.

One of the complications I found with MAP was to transition from `arcademode`
into `servicemode` -- something that can demand to take out the SD card from the
Raspberry Pi to delete some files.

My proposal is that the system always runs in `arcademode` but if you press a
bottom and/or move the joystick at boot time, then the system goes into
`servicemode`.

### Detecting inputs at boot time

First, we need an script that detect if the joystick (the one in
`/dev/input/js0`) has moved or a button has been pressed.

```bash
#/bin/bash
#file: /home/pi/scripts/mame-joystick-detect.sh

# Testing joystick movement or buttons
JOY0=/dev/input/js0

# Waiting for some input
timeout 5s jstest --event ${JOY0} > /tmp/joystick0

# Checking if some input has occured

INPUT=$(grep -e "type 1," -e "type 2," /tmp/joystick0 | wc -l)

if [ $INPUT -eq 0 ]; then
	touch /tmp/arcademode-confirm
	exit 0  # input not-detected!
fi
```
