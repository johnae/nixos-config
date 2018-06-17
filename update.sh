#!/bin/sh

PREFIX=$1
DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
SUDO=
if [ "$(id -u)" != "0" ]; then
	SUDO=sudo
fi

$SUDO cp configuration.nix $PREFIX/etc/nixos/configuration.nix
$SUDO cp system-packages.nix $PREFIX/etc/nixos/system-packages.nix
$SUDO cp -R overlays $PREFIX/etc/nixos/overlays
$SUDO cp -R packages $PREFIX/etc/nixos/packages

USERNAME=$($SUDO cat $PREFIX/etc/nixos/configuration.nix | grep extraUsers | head -1 | awk -F'.' '{print $3}' | awk '{print $1}')

ICON=$($SUDO cat $PREFIX/etc/nixos/meta.nix | grep userIcon | awk -F'"' '{print $2}')

$SUDO rm -rf $PREFIX/home/shared
$SUDO cp -R shared $PREFIX/home/shared

$SUDO rm -rf $PREFIX/var/lib/AccountsService/icons
$SUDO cp -R user-icons $PREFIX/var/lib/AccountsService/icons

$SUDO mkdir -p $PREFIX/var/lib/AccountsService/users
cat <<EOF | $SUDO tee $PREFIX/var/lib/AccountsService/users/$USERNAME
[User]
XSession=none+i3
Icon=$ICON
SystemAccount=false
EOF

if [ -z "$PREFIX" ]; then
    $SUDO nixos-rebuild switch
fi
