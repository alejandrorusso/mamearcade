#!/bin/bash
#file: clone.sh

URL=https://github.com/alejandrorusso/mamearcade

if [ ! -d ./mamearcade ]; then
  # Cloning scripts
  git clone $URL
  touch ./mamearcade/deploynow
fi

cd ./mamearcade

CURRENT=$(git rev-parse HEAD)
REMOTE=$(git ls-remote $URL HEAD | awk '{ print $1}')

if [[ $CURRENT == $REMOTE ]]; then
    echo No need to pull
else
    # It should never create a conflict
    git pull
    touch ./deploynow
fi

if [ -f ./deploynow ]; then
    echo "Copying the scripts"
else
    echo "Scripts already deployed"
fi

rm -f ./deploynow
