#!/bin/sh

PREFIX=$1
DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
SUDO=
if [ "$(id -u)" != "0" ]; then
	SUDO=sudo
fi

FILES="configuration.nix system-packages.nix meta.nix"
DIRECTORIES="overlays packages shared user-icons"

OIFS=$IFS
IFS=" "

for FILE in $FILES; do
    if [ -f $FILE ]; then
        echo "Copying file $FILE to $PREFIX/etc/nixos/$FILE"
        $SUDO cp $FILE $PREFIX/etc/nixos/$FILE
    else
        echo "Not copying $FILE as it doesn't exist or is not a regular file"
    fi
done

for DIR in $DIRECTORIES; do
    if [ -d $DIR ]; then
        $SUDO rm -rf $PREFIX/etc/nixos/$DIR
        echo "Copying directory $DIR to $PREFIX/etc/nixos/$DIR"
        $SUDO cp -R $DIR $PREFIX/etc/nixos/$DIR
    else
        echo "Not copying $DIR as it doesn't exist or is not a directory"
    fi
done

IFS=$OIFS

if [ -z "$PREFIX" ]; then
    $SUDO nixos-rebuild switch
fi
