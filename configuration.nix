{ config, pkgs, lib, ... }:

let
  meta = import ./meta.nix;
  stdenv = pkgs.stdenv;
  pango = attrs: str:
        "<span " +
        (lib.concatStringsSep " " (lib.mapAttrsToList (name: value: '' ${name}='${value}' '') attrs)) +
        ">" + str + "</span>";

  filesIfExist = with builtins; files:
     filter (file: pathExists file) files;

in

{
  imports = [
    ./hardware-configuration.nix
  ] ++ filesIfExist [ ./wireguard.nix ];

  nix.trustedUsers = [ "root" "${meta.userName}" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  #boot.kernelPackages = pkgs.linuxPackages_4_20;
  boot.kernelParams = meta.kernelParams;
  boot.extraModulePackages = with config.boot.kernelPackages; [ wireguard ];

  boot.kernel.sysctl = meta.sysctl;

  hardware.cpu.intel.updateMicrocode = true;
  hardware.opengl.enable = true;
  hardware.opengl.driSupport = true;
  hardware.opengl.driSupport32Bit = true;
  hardware.u2f.enable = true;

  sound.enable = true;
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.package = pkgs.pulseaudioFull;
  hardware.pulseaudio.support32Bit = true;

  hardware.bluetooth.enable = true;

  networking.hostName = meta.hostName;
  networking.extraHosts = "127.0.1.1 ${meta.hostName}";
  networking.wireless.iwd.enable = true;
  networking.nameservers = [ "1.0.0.1" "1.1.1.1" "2606:4700:4700::1111" ];

  i18n.consoleFont = meta.consoleFont;
  i18n.consoleKeyMap = meta.consoleKeyMap;
  i18n.defaultLocale = meta.defaultLocale;

  # additional fs options
  fileSystems."/".options = [ "subvol=@" "rw" "noatime"
                              "compress=zstd" "ssd" "space_cache" ];

  fileSystems."/home".options = [ "subvol=@home" "rw" "noatime"
                                  "compress=zstd" "ssd" "space_cache" ];

  fileSystems."/var".options = [ "subvol=@var" "rw" "noatime"
                                 "compress=zstd" "ssd" "space_cache" ];

  time.timeZone = meta.timeZone;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    (import ./overlays/packages.nix)
  ];

  environment.systemPackages = import ./system-packages.nix pkgs;

  environment.shells = [ pkgs.bashInteractive pkgs.zsh pkgs.fish ];
  environment.pathsToLink = [ "/etc/gconf" ];

  powerManagement.enable = true;
  powerManagement.powertop.enable = true;

  virtualisation.docker.enable = true;
  virtualisation.libvirtd.enable = true;

  programs.gnupg.agent.enable = true;
  programs.gnupg.agent.enableSSHSupport = true;
  programs.gnupg.dirmngr.enable = true;

  programs.ssh.startAgent = false;
  programs.ssh.knownHosts = meta.knownHosts;

  programs.fish.enable = true;
  programs.dconf.enable = true;
  programs.light.enable = true;

  services.kbfs.enable = true;
  services.keybase.enable = true;

  services.pcscd.enable = true;
  services.cron.enable = true;
  services.avahi.enable = true;
  services.avahi.nssmdns = true;
  services.gvfs.enable = true;
  services.gnome3.gnome-keyring.enable = true;
  services.gnome3.sushi.enable = true;
  services.openssh.enable = true;

  services.printing.enable = true;
  services.printing.drivers = [ pkgs.gutenprint ];

  services.dbus.packages = with pkgs; [ gnome2.GConf gnome3.gcr gnome3.dconf gnome3.sushi ];
  services.udev.packages = with pkgs; [ gnome3.gnome-settings-daemon ];

  services.logind.lidSwitch = "suspend-then-hibernate";
  environment.etc."systemd/sleep.conf".text = "HibernateDelaySec=8h";

  services.syncthing = {
    enable = true;
    user = "${meta.userName}";
    group = "${meta.userName}";
    dataDir = "/home/${meta.userName}/.config/syncthing";
    openDefaultPorts = true;
  };

  ## the NixOS module doesn't work well when logging in from console
  ## which is the case when running sway - a wayland compositor (eg. no x11 yay)
  ## actually - the redshift package (see below) is a patched version that works
  ## with wayland
  systemd.user.services.redshift =
  {
    description = "Redshift color temperature adjuster";
    wantedBy = [ "default.target" ];
    enable = true;
    serviceConfig = {
      ExecStart = ''
        ${pkgs.redshift-wl}/bin/redshift \
          -l 59.344:18.045 \
          -t 6500:2700 \
          -b 1:1 \
          -m wayland
      '';
      RestartSec = 3;
      Restart = "always";
    };
  };

  services.upower.enable = true;

  systemd.timers.rbsnapper = {
    description = "run rbsnapper every 30 minutes and 5 minutes after boot";
    wantedBy = [ "timers.target" ]; # enable it and autostart

    timerConfig = {
      OnBootSec = "5m"; # always run rbsnapper 5 minutes after boot
      OnUnitInactiveSec = "30m"; # run rbsnapper 30 minutes after last run
    };
  };

  systemd.services.rbsnapper = rec {

    description = with meta;
       "Snapshot and remote backup of /home to ${backupDestination}";

    preStart = with pkgs; ''
      ${udev}/bin/systemctl set-environment \
        STARTED_AT=$(${coreutils}/bin/date +%s)
    '';

    script = with meta; with pkgs; ''
      ${udev}/bin/systemd-inhibit \
        --what="idle:shutdown:sleep" \
        --who="btr-snap" --why="Backing up /home" --mode=block \
          ${btr-snap}/bin/btr-snap /home \
            ${backupDestination} ${backupPort} ${backupSshKey}
    '';

    postStop = with lib; with pkgs; ''
      if [ -e /run/user/1337/env-vars ]; then
         source /run/user/1337/env-vars
      fi
      ENDED_AT=$(${coreutils}/bin/date +%s)
      DURATION=$(($ENDED_AT - $STARTED_AT))
      NOTIFY="${notify-desktop}/bin/notify-desktop"
      if [ "$EXIT_STATUS" = "0" ]; then
         MSG="${pango { font_weight = "bold"; } "Completed"} ${toLower description} in $DURATION"s.
         ${busybox}/bin/su $USER -s /bin/sh -c \
           "$NOTIFY -i emblem-insync-syncing \"Backup\" \"$MSG\""
      else
         MSG="${pango { font_weight = "bold"; } "Failed" } ${toLower description} after $DURATION"s.
         ${busybox}/bin/su $USER -s /bin/sh -c \
           "$NOTIFY -i dialog-error -u critical \"Backup\" \"$MSG\""
      fi;
    '';
  };

  ## usb devices can interfere with sleep without the below
  systemd.services.disable-usb-wakeup = rec {
    description = "Disable USB wakeup";
    enable = true;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = "yes";
    };
    script = ''
      echo XHC > /proc/acpi/wakeup
    '';
    postStop = ''
      echo XHC > /proc/acpi/wakeup
    '';
    wantedBy = [ "multi-user.target" ];
  };

  systemd.user.services.pasuspender = rec {
    description = "Fix PulseAudio after resume from suspend";
    after = [ "suspend.target" ];
    enable = true;
    serviceConfig = {
      Type = "oneshot";
    };
    environment = {
      XDG_RUNTIME_DIR = "/run/user/%U";
    };
    script = ''
      ${pkgs.pulseaudioFull}/bin/pasuspender ${pkgs.coreutils}/bin/true
    '';
    wantedBy = [ "suspend.target" ];
  };

  fonts.fonts = with pkgs; [
     google-fonts
     source-code-pro
     office-code-pro-font
     system-san-francisco-font
     san-francisco-mono-font
     font-awesome_5
     powerline-fonts
     roboto
     fira-code
     fira-code-symbols
     nerdfonts
  ];

  security.pam.services."${meta.userName}".enableGnomeKeyring = true;
  security.pam.services.swaylock = {
    text = ''
      auth include login
    '';
  };

  users.defaultUserShell = pkgs.fish;
  users.mutableUsers = false;
  users.groups."${meta.userName}".gid = 1337;
  users.extraUsers."${meta.userName}" = {
    isNormalUser = true;
    uid = 1337;
    extraGroups = [ "wheel" "docker" "video" "audio" "libvirtd" ];
    description = meta.userDescription;
    shell = pkgs.fish;
    hashedPassword = meta.userPassword;
  };

  system.stateVersion = "18.03";

}