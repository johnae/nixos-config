#!/bin/sh

DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)

## This script bootstraps a nixos install. The assumptions are:
# 1. You want an EFI System Partition (500MB) - so no BIOS support
# 2. You want encrypted root and swap
# 3. You want swap space size to be half of RAM as per modern standards (eg. see https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/installation_guide/sect-disk-partitioning-setup-x86#sect-recommended-partitioning-scheme-x86)
# 4. You want to use btrfs for everything else and you want to use subvolumes for /, /var and /home
# 5. You want to not care about atime and you want to compress your fs using zstd

# set -x

## Generally this should really be /dev/random as that will be cryptographically of high quality,
## however for testing purposes I allow it to be overridden. Just don't do this unless you have a
## good reason. For example, in a VM when testing the install script, it may be beneficial to use urandom
## instead as it will likely generate entropy properly as opposed to random.

DEVRANDOM=${DEVRANDOM:-/dev/random}

## This will be formatted! It should be the path to the device, not a partition.
DISK=$1
HNAME=$2 ## hostname

if [ -z "$DISK" ]; then
    echo "You must set the DISK env var (this WILL be formatted so be careful!)"
    exit 1
fi

if [ ! -e "$DISK" ]; then
    echo "'$DISK' does not exist"
    exit 1
fi

if [ -z "$HNAME" ]; then
    echo "You must provide a hostname as the second argument"
    exit 1
fi

echo "Will completely erase and format '$DISK', proceed? (y/n)"
read answer
if ! echo "$answer" | grep '^[Yy].*' 2>&1>/dev/null; then
    echo "Ok bye."
    exit
fi

# clear out the disk completely
wipefs -fa $DISK
sgdisk -Z $DISK

efi_space=500M # EF00 EFI Partition
luks_key_space=3M # 8300
# set to half amount of RAM
swap_space=$(($(free --giga | tail -n+2 | head -1 | awk '{print $2}') / 2))G # 8300
# special case when there's very little ram - perhaps this should be dealt with differently?
if [ "$swap_space" = "0G" ]; then
    swap_space="1G"
fi
# rest (eg. root) will use the remaining space (btrfs) 8300

# now ensure there's a fresh GPT on there
sgdisk -og $DISK

sgdisk -n 0:0:+$efi_space -t 0:ef00 -c 0:"efi" $DISK # 1
sgdisk -n 0:0:+$luks_key_space -t 0:8300 -c 0:"cryptkey" $DISK # 2
sgdisk -n 0:0:+$swap_space -t 0:8300 -c 0:"swap" $DISK # 3
sgdisk -n 0:0:0 -t 0:8300 -c 0:"root" $DISK # 4

DISK_EFI=$DISK"1"
DISK_CRYPTKEY=$DISK"2"
DISK_SWAP=$DISK"3"
DISK_ROOT=$DISK"4"

sgdisk -p $DISK

# make sure everything knows about the new partition table
partprobe $DISK
fdisk -l $DISK

# create a disk for the key used to decrypt the other volumes
# you should be able to remember this one
cryptsetup luksFormat $DISK_CRYPTKEY
cryptsetup luksOpen $DISK_CRYPTKEY cryptkey
## dm-0

# dump random data into what will be our key
dd if=$DEVRANDOM of=/dev/mapper/cryptkey bs=1024 count=14000

# create encrypted swap using above key
cryptsetup luksFormat --key-file=/dev/mapper/cryptkey $DISK_SWAP
DM_SWAP=dm-1

# create the encrypted root with a key you can remember
cryptsetup luksFormat $DISK_ROOT
DM_ROOT=dm-2

# but generally we want to use the above generated key which we decrypt on boot
cryptsetup luksAddKey $DISK_ROOT /dev/mapper/cryptkey

# open those crypt volumes now
cryptsetup luksOpen --key-file=/dev/mapper/cryptkey $DISK_SWAP cryptswap
mkswap /dev/mapper/cryptswap

cryptsetup luksOpen --key-file=/dev/mapper/cryptkey $DISK_ROOT cryptroot
mkfs.btrfs -L root /dev/mapper/cryptroot

# and create the efi boot partition
mkfs.vfat $DISK_EFI

DECRYPTED_SWAP_UUID=$(ls -lah /dev/disk/by-uuid/ | grep $DM_SWAP | awk '{print $9}')
# enable swap on the decrypted cryptswap
swapon /dev/disk/by-uuid/$DECRYPTED_SWAP_UUID

DECRYPTED_ROOT_UUID=$(ls -lah /dev/disk/by-uuid/ | grep $DM_ROOT | awk '{print $9}')
# mount the decrypted cryptroot to /mnt (btrfs)
mount -o rw,noatime,compress=zstd,ssd,space_cache /dev/disk/by-uuid/$DECRYPTED_ROOT_UUID /mnt

# now create btrfs subvolumes we're interested in having
cd /mnt
btrfs subvolume create @ ## root
mkdir -p "@/boot" "@/home" "@/var"
btrfs subvolume create @home ## home ofc
btrfs subvolume create @var ## var ofc
cd $DIR
# umount the "real" root and mount those subvolumes in place instead
umount /mnt

# mount the "root" (@) subvolume to /mnt
mount -o rw,noatime,compress=zstd,ssd,space_cache,subvol=@ /dev/disk/by-uuid/$DECRYPTED_ROOT_UUID /mnt
# mount @home subvolume to /mnt/home
mount -o rw,noatime,compress=zstd,ssd,space_cache,subvol=@home /dev/disk/by-uuid/$DECRYPTED_ROOT_UUID /mnt/home
# mount @var subvolume to /mnt/var
mount -o rw,noatime,compress=zstd,ssd,space_cache,subvol=@var /dev/disk/by-uuid/$DECRYPTED_ROOT_UUID /mnt/var

BOOT_UUID=$(ls -lah /dev/disk/by-uuid/ | grep $(basename $DISK_EFI) | awk '{print $9}')
# and mount the boot partition
mount /dev/disk/by-uuid/$BOOT_UUID /mnt/boot

nixos-generate-config --root /mnt
cat /mnt/etc/nixos/hardware-configuration.nix | grep -v "boot\.initrd\.luks" | grep -v "^}\$" > /mnt/etc/nixos/hardware-configuration.nix_tmp

CRYPTKEY_UUID=$(ls -lah /dev/disk/by-uuid/ | grep $(basename $DISK_CRYPTKEY) | awk '{print $9}')
ROOT_UUID=$(ls -lah /dev/disk/by-uuid/ | grep $(basename $DISK_ROOT) | awk '{print $9}')
SWAP_UUID=$(ls -lah /dev/disk/by-uuid/ | grep $(basename $DISK_SWAP) | awk '{print $9}')

cat <<EOF>> /mnt/etc/nixos/hardware-configuration.nix_tmp
  boot.initrd.luks.devices = {
    cryptkey = {
      device = "/dev/disk/by-uuid/$CRYPTKEY_UUID";
    };

    cryptroot = {
      device = "/dev/disk/by-uuid/$ROOT_UUID";
      keyFile = "/dev/mapper/cryptkey";
    };

    cryptswap = {
      device = "/dev/disk/by-uuid/$SWAP_UUID";
      keyFile = "/dev/mapper/cryptkey";
    };
  };
}
EOF

diff /mnt/etc/nixos/hardware-configuration.nix /mnt/etc/nixos/hardware-configuration.nix_tmp
rm /mnt/etc/nixos/hardware-configuration.nix
mv /mnt/etc/nixos/hardware-configuration.nix_tmp /mnt/etc/nixos/hardware-configuration.nix

echo "Installing mkpasswd"
nix-env -i mkpasswd

cp meta-template.nix /mnt/etc/nixos/meta.nix

sed -i"" "s|<HOSTNAME>|$HNAME|g" /mnt/etc/nixos/meta.nix

## NOTE: -s -p aren't posix compatible but they will work just fine for this
while [ -z "$USERPASS" ]; do
    echo "Please type your password."
    read -s -p "password: " USERPASS
    echo "Please retype your password."
    read -s -p "password again: " USERPASS2
    if [ "$USERPASS" != "$USERPASS2" ]; then
        echo "Different passwords given, again please."
        unset USERPASS
    fi
    unset USERPASS2
done

PASS=$(mkpasswd -m sha-512 -s <<< $USERPASS)
unset USERPASS

sed -i"" "s|<PASSWORD>|$PASS|g" /mnt/etc/nixos/meta.nix
unset PASS

echo "Now make any last changes to meta.nix..."
vi /mnt/etc/nixos/meta.nix

./update.sh /mnt

echo "Now modify anything else you need in /mnt/etc/nixos/meta.nix"
echo "then run 'nixos-install'"
