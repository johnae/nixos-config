## NixOS setup

This is my NixOS setup. It encrypts all disks including swap, uses compressed btrfs as fs.

You might also be interested in my user dotfiles repo here: [nixdot](https://github.com/johnae/nixdot).

Installation goes something like (for a fresh install, unformatted disks etc):

Connect to a wifi first:

```shell
wpa_supplicant -B -i <ifaceName> -c <(wpa_passphrase '<NetworkName>' '<password here>')
```

```shell
./bootstrap.sh /dev/sda theHostname
```

Now create a `wifi-configuration.nix` in `/mnt/etc/nixos/`, should look something like:

```nix
{ config, pkgs, ... }:

{
	networking.wireless.networks = {
		"SomeNetwork" = {
			psk = "somePassWord";
		};
		"Other network here" = {
			psk = "trustno1";
		};
		"Puddle" = {
			psk = "dripdrop";
		};
		"The Ocean" = {
			psk = "water?";
		};
		"free.wifi" = {};
	};
}

```

```shell
nixos-install
```