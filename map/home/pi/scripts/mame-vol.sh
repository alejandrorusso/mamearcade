#!/bin/bash

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
