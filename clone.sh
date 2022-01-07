#!/bin/bash
#file: clone.sh

## Clone
URL=https://github.com/alejandrorusso/mamearcade

if [ ! -d ./mamearcade ]; then
  # Cloning scripts
  git clone $URL
  touch ./mamearcade/deploynow
fi

cd ./mamearcade

CURRENT=$(git rev-parse HEAD)
REMOTE=$(git ls-remote $URL HEAD | awk '{ print $1}')

if [[ $CURRENT != $REMOTE ]]; then
    # It should never create a conflict
    git pull
    touch ./deploynow
fi

## Deploy
FILES=$(find ./map/ -type f)

if [ ! -f ./deploynow ]; then
    echo "Scripts already deployed"
    echo "Nothing to do :("
    exit 0
fi

for f in $FILES
do
    echo $f
    echo ${f#./map}
done

## Execute post-processing

rm -f ./deploynow
