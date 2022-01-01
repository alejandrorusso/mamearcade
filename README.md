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

After studying the project for some time. I introduced three modifications to
fit my needs.

## 1. No need to decide between arcademode and servicemode

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

### Detecting joysticks' inputs at boot time

First, we need [an
script](https://github.com/alejandrorusso/mamearcade/blob/main/map/home/pi/scripts/mame-joystick-detect.sh)
that detect if the joystick (the one in `/dev/input/js0`) has moved or a button
has been pressed.

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

The script waits five seconds for inputs from either a joystick movement (`type
1` event) or a pressed button (`type 2` event). If *no input* gets detected,
then the script creates the empty file `/tmp/arcademode-confirm`. We will see
the utility of this file later on.

We also create a [systemd service to run this script at runtime](https://github.com/alejandrorusso/mamearcade/blob/main/map/etc/systemd/system/mame-question.service).

```
[Unit]
Description=Reading input from joystick

[Service]
Type=oneshot
ExecStart=/bin/bash /home/pi/scripts/mame-joystick-detect.sh

[Install]
WantedBy=multi-user.target
```

### Asking for joysticks' inputs before launching MAME

Now, we need to modify the service responsible to launch MAME from this:

```
[Unit]
Description=MAME Appliance Autostart service
Conflicts=getty@tty1.service smbd.service nmbd.service rng-tools.service cron.service mame-artwork-mgmt.service
Requires=local-fs.target
After=local-fs.target

[Service]
User=pi
Group=pi
PAMName=login
Type=simple
ExecStart=/home/pi/scripts/autostart.sh
Restart=on-abort
RestartSec=5
TTYPath=/dev/tty1
StandardInput=tty

[Install]
WantedBy=multi-user.target
Also=shutdown.service
```

[into
this:](https://github.com/alejandrorusso/mamearcade/blob/main/map/etc/systemd/system/mame-autostart.service)

```
[Unit]
Description=MAME Appliance Autostart service
After=mame-question.service
ConditionPathExists=/tmp/arcademode-confirm
Conflicts=getty@tty1.service smbd.service nmbd.service rng-tools.service cron.service mame-artwork-mgmt.service

[Service]
User=pi
Group=pi
PAMName=login
Type=simple
EnvironmentFile=/etc/environment
ExecStart=/home/pi/scripts/autostart.sh
Restart=on-abort
RestartSec=5
TTYPath=/dev/tty1
StandardInput=tty

[Install]
WantedBy=multi-user.target
Also=shutdown.service
```

The modifications include

- considering launching this service after asking for joysticks' inputs (see line
  `After=mame-question.service`), and
- launching MAME only under the existence of the file `/tmp/arcademode-confirm`
(see line `ConditionPathExists=/tmp/arcademode-confirm`) -- recall that such
file will exist only if **there were no joysticks' inputs**!.

So, if there were no joysticks' inputs, then MAME will execute by calling
`/home/pi/scripts/autostart.sh`. Otherwise, all the services declared as
conflicting above will be successfully launched, which will allow users to login
into the system as in `servicemode`.

## 2. Button to mute / unmute sound

I plan to have my arcade in my office. So, having an arcade with noise all the
time might disturb the working environment. In this light, I propose another
modification which consists on adding a button to the Raspberry Pi (GPIO-based
interface) to lower the volume, mute, and unmute the sound. In that manner, the
arcade can show gameplay but without disturbing your work mates. People that
want to play, however, can just unmute and enjoy the arcade from time to time.

The goal is that if you keep pressing the button for some seconds (no more than
5), you will hear that the volume change to a minimum. Then, if you keep
pressing the button again for some seconds, the arcade will mute. Finally, if
you keep pressing the button again, you will see that the arcade unmute and has
a high volume.

The hardware that you need is simply a *push switch* -- I followed most of the
idea from [this post](http://razzpisampler.oreilly.com/ch07.html). You need to
connect two cables into the push switch: one into the GPIO 4 (look for pin 4 in
your board) and another into ground (look for GND in your board). You can change
the GPIO 4 for whatever GPIO available on the board.

We start by writing [an script to change the volume when detecting every five
seconds that the button has been
pressed](https://github.com/alejandrorusso/mamearcade/blob/main/map/home/pi/scripts/mame-vol.sh).

```bash
#!/bin/bash
#file:/home/pi/scripts/mame-vol.sh

HIGH="95%"
LOW="70%"
MUTE="0%"
BREAK=5

# Initialize GPIO pin
echo 4 > /sys/class/gpio/unexport         # Deactivate GPIO 4
echo 4 > /sys/class/gpio/export           # Activate GPIO 4
#echo in > /sys/class/gpio/gpio4/direction # Input signal

amixer cset numid=1 $HIGH

while true; do
	read SIGNAL < /sys/class/gpio/gpio4/value

	# If the signals are different, the button was pressed
	if [ $SIGNAL -eq 0 ]; then
		echo "Volume button pressed"
		CHECK_VOL=$(amixer | grep Mono: | awk -F"[\[\]]" '{print $2}')

		echo "Current volume:" $CHECK_VOL

		case $CHECK_VOL in
		$HIGH)
			echo Setting volume to low
			amixer cset numid=1 $LOW  ;;
		$LOW)
			echo Setting volume to mute
			amixer cset numid=1 '$MUTE'   ;;
		$MUTE)
			echo Setting volume to high
			amixer cset numid=1 $HIGH  ;;
		*)
			amixer cset numid=1 $HIGH  ;;
		esac
	fi
	sleep $BREAK
done
```

We also write [a systemd service to launch this script only when being in
`arcademode`](https://github.com/alejandrorusso/mamearcade/blob/main/map/etc/systemd/system/mame-volume.service).

```
[Unit]
Description=Controlling volume for MAME with a button
After=mame-question.service
ConditionPathExists=/tmp/arcademode-confirm

[Service]
User=pi
Group=pi
ExecStart=/bin/bash /home/pi/scripts/mame-vol.sh

[Install]
WantedBy=multi-user.target
```

Observe that the script is run only if no joysticks' inputs are detected (see
`After=mame-question.service` and
`ConditionPathExists=/tmp/arcademode-confirm`).

## 3. Showing IP in login screen

Sometimes it is useful to know the IP of your MAP when entering into
`servicemode`. So, it is enough to modify [the file `/etc/issue`](https://github.com/alejandrorusso/mamearcade/blob/main/map/etc/issue):

```
Raspbian GNU/Linux 10 \n \l

S E R V I C E      M O D E

IP: \4{eth0}
```

# TODOs

Here I write some possible extensions and or aspects that I would like to
explore further with MAP.

- So far, the joysticks' input come from `/dev/input/js0`, but why not
  generalize this to consider any joystick in the system?
- It is not clear when exactly at boot time the script is waiting for the
  joysticks input. At this point, when you see the MAME splash screen, you
  should start moving the joystick or pressing a button. While this works, it
  would be nice to play some sound to indicate exactly when the input is
  expected.
- Make sure that when in `arcademode`, all network is down -- this is not the case
  right now. For instance, we have `wpa_supplicant` service up.
- The patch does not work for MAME 0238. The lines where the patch is applied
  has been changed, and you need to do the patching manually. So, `mame-updater.sh`
  needs to be changed and a new patch file needs to be created for MAME 0238.
  What about 0239?
- How do we make that modifications of scripts automatically are deployed? I am
  planning making many MAPs :)
