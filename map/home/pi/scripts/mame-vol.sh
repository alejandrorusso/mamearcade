#!/bin/bash
#file:/home/pi/scripts/mame-vol.sh

HIGH='95%'
MED='85%'
LOW='72%'
MUTE='0%'

GPIOPIN=4   # We use GPIO 4

# Initialize GPIO pin
echo $GPIOPIN > /sys/class/gpio/unexport  # Deactivate GPIO pin
echo $GPIOPIN > /sys/class/gpio/export    # Activate GPIO pin
sleep 0.1                                 # A small delay is required so that the system has time
                                          # to properly create and set the file's permission
echo in > /sys/class/gpio/gpio${GPIOPIN}/direction # Input signal
echo both > /sys/class/gpio/gpio${GPIOPIN}/edge    # We use the interrupt controller to avoid a CPU spin loop

amixer -q cset numid=1 $MED

while true; do
  inotifywait -q -e modify /sys/class/gpio/gpio${GPIOPIN}/value > /dev/null      # CPU efficient wait
  read SIGNAL < /sys/class/gpio/gpio${GPIOPIN}/value     # 0=Pressed, 1=Released/Not pressed

  if [ $SIGNAL -eq 0 ]; then    # 0=Pressed, 1=Released/Not pressed
    # Volume button pressed
    CHECK_VOL=$(amixer | awk -F'[\[\]]' '/Mono: Playback/ {print $2}')

    case $CHECK_VOL in
      $HIGH)
        # Setting volume to medium
        amixer -q cset numid=1 $MED ;;
      $MED)
        # Setting volume to low
        amixer -q cset numid=1 $LOW ;;
      $LOW)
        # Setting volume to mute
        amixer -q cset numid=1 "$MUTE" ;;
      $MUTE)
        # Setting volume to high
        amixer -q cset numid=1 $HIGH ;;
      *)
        # Setting volume to medium (default)
        amixer -q cset numid=1 $MED ;;
    esac
  fi
done
