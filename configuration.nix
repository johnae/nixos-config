{ config, pkgs, lib, ... }:

let
  meta = import ./meta.nix;
  stdenv = pkgs.stdenv;

in

{
  imports =
    [ ./hardware-configuration.nix
      ./wifi-configuration.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = meta.kernelParams;
  boot.extraModulePackages = with config.boot.kernelPackages; [ wireguard ];

  hardware.cpu.intel.updateMicrocode = true;
  hardware.opengl.enable = true;
  hardware.opengl.driSupport = true;
  hardware.u2f.enable = true;

  sound.enable = true;
  hardware.pulseaudio = {
    enable = true;
    package = pkgs.pulseaudioFull;
  };
  hardware.bluetooth.enable = true;

  networking.hostName = meta.hostName;
  networking.extraHosts = "127.0.1.1 ${meta.hostName}";
  networking.wireless.enable = true;
  networking.nameservers = [ "8.8.8.8" "8.8.4.4" ];

  i18n.consoleFont = meta.consoleFont;
  i18n.consoleKeyMap = meta.consoleKeyMap;
  i18n.defaultLocale = meta.defaultLocale;

  # additional fs options
  fileSystems."/".options = [ "subvol=@" "rw" "noatime" "compress=zstd" "ssd" "space_cache" ];
  fileSystems."/home".options = [ "subvol=@home" "rw" "noatime" "compress=zstd" "ssd" "space_cache" ];
  fileSystems."/var".options = [ "subvol=@var" "rw" "noatime" "compress=zstd" "ssd" "space_cache" ];

  time.timeZone = meta.timeZone;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    (import ./overlays/packages.nix)
  ];

  environment.systemPackages = import ./system-packages.nix pkgs;

  environment.shellInit = ''
    gpg-connect-agent /bye
    export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
  '';

  environment.shells = [ pkgs.bashInteractive pkgs.zsh pkgs.fish ];
  environment.pathsToLink = [ "/etc/gconf" ];

  powerManagement.cpuFreqGovernor = "powersave";
  powerManagement.enable = true;
  powerManagement.powertop.enable = true;
  powerManagement.resumeCommands = ''
    ${pkgs.killall}/bin/killall -9 gpg-agent
  '';

  virtualisation.docker.enable = true;

  programs.gnupg.agent = { enable = true; enableSSHSupport = true; };
  programs.ssh.startAgent = false;
  programs.ssh.knownHosts = meta.knownHosts;
  programs.fish.enable = true;
  programs.dconf.enable = true;

  services.pcscd.enable = true;
  services.cron.enable = true;
  services.avahi.enable = true;
  services.avahi.nssmdns = true;
  services.flatpak.enable = true;
  services.gnome3.gnome-keyring.enable = true;
  services.openssh.enable = true;

  services.printing.enable = true;
  services.printing.drivers = [ pkgs.gutenprint ];

  services.dbus.packages = with pkgs; [ gnome2.GConf gnome3.gcr gnome3.dconf ];
  services.udev.packages = with pkgs; [ gnome3.gnome-settings-daemon ];

  services.syncthing = {
    enable = true;
    user = "${meta.userName}";
    dataDir = "/home/${meta.userName}/.config/syncthing";
  };

  services.redshift = {
    package = pkgs.redshiftwl;
    enable = true;
    latitude = "59.344";
    longitude = "18.045";
    temperature.day = 6500;
    temperature.night = 2700;
  };

  services.upower.enable = true;

  systemd.timers.rbsnapper = {
    description = "run rbsnapper every 30 minutes and 5 minutes after boot";
    wantedBy = [ "timers.target" ]; # enable it and autostart

    timerConfig = {
      OnBootSec = "5m"; # always run rbsnapper 5 minutes after boot
      OnUnitInactiveSec = "30m"; # run rbsnapper 30 minutes after it last finished
    };
  };

  systemd.services.rbsnapper = rec {
    description = "Snapshot and remote backup of /home to ${meta.backupDestination}";
    preStart = ''
      ${pkgs.udev}/bin/systemctl set-environment BACKUP_STARTED_AT=$(${pkgs.coreutils}/bin/date +%s)
    '';
    script = ''
      ${pkgs.udev}/bin/systemd-inhibit --what="idle:shutdown:sleep" \
                                       --who="btr-snap" --why="Backing up /home" --mode=block \
                                       ${pkgs.btr-snap}/bin/btr-snap /home ${meta.backupDestination} ${meta.backupPort} ${meta.backupSshKey}
    '';
    postStop = ''
      if [ -e /run/user/1337/env-vars ]; then
         source /run/user/1337/env-vars
      fi
      BACKUP_ENDED_AT=$(${pkgs.coreutils}/bin/date +%s)
      BACKUP_DURATION=$(($BACKUP_ENDED_AT - $BACKUP_STARTED_AT))
      if [ "$EXIT_STATUS" = "0" ]; then
         ${pkgs.busybox}/bin/su $USER -s /bin/sh -c "${pkgs.notify-desktop}/bin/notify-desktop -i /home/shared/icons/cloud-computing-3.svg \
                                                      Backup \"Completed ${lib.toLower description} in $BACKUP_DURATION\"s."
      else
         ${pkgs.busybox}/bin/su $USER -s /bin/sh -c "${pkgs.notify-desktop}/bin/notify-desktop -u critical -i /home/shared/icons/error.svg \
                                                      Backup \"Failed ${lib.toLower description} after $BACKUP_DURATION\"s."
      fi;
    '';
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
     system-san-francisco-font
     san-francisco-mono-font
     font-awesome_4
     font-droid
     powerline-fonts
     roboto
     fira-code
     fira-code-symbols
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
    extraGroups = [ "wheel" "docker" "video" "audio" ];
    description = meta.userDescription;
    shell = pkgs.fish;
    hashedPassword = meta.userPassword;
  };

  system.stateVersion = "18.03";

}