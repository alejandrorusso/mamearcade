#! /bin/bash

BOOTSOUND=/home/pi/scripts/coin.wav
TIMEOUT=5
JOY0=/dev/input/js0
JOY1=/dev/input/js1

aplay -q $BOOTSOUND  &      # Boot sound

inotifywait -q -t $TIMEOUT -e modify $JOY0 $JOY1 > /dev/null

if [ $?  -eq 0 ] ;  then  # Joystick activated
  aplay -q /home/pi/scripts/service-mode.wav     # Service Mode
else
  touch /tmp/arcademode-confirm                  # Arcade Mode
fi
