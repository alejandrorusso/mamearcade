#/bin/sh

# Testing joystick
# Todo: generalize and detect the joysticks

JOY0=/dev/input/js0

# Waiting for some input
timeout 5s jstest --event ${JOY0} > /tmp/joystick0

# Checking the input

INPUT=$(grep -e "type 1," -e "type 2," /tmp/joystick0 | wc -l) 

if [ $INPUT -eq 0 ]; then 
	touch /tmp/arcademode-confirm
	exit 0  # input not-detected!
fi
