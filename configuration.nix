# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

# For machine specific stuff
let
  meta = import ./meta.nix;
  stdenv = pkgs.stdenv;

in

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # Include the wireless networks. This must be a private file.
      ./wifi-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = meta.kernelParams;
  boot.extraModulePackages = with config.boot.kernelPackages; [ wireguard ];

  hardware.cpu.intel.updateMicrocode = true;
  hardware.opengl.enable = true;
  hardware.opengl.driSupport = true;
  hardware.u2f.enable = true;

  networking.hostName = meta.hostName;
  networking.extraHosts = "127.0.1.1 ${meta.hostName}";
  networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.nameservers = [ "8.8.8.8" "8.8.4.4" ];

  # Select internationalisation properties.
  i18n = {
    consoleFont = meta.consoleFont;
    consoleKeyMap = meta.consoleKeyMap;
    defaultLocale = meta.defaultLocale;
  };

  # additional fs options
  fileSystems."/".options = [ "subvol=@" "rw" "noatime" "compress=zstd" "ssd" "space_cache" ];
  fileSystems."/home".options = [ "subvol=@home" "rw" "noatime" "compress=zstd" "ssd" "space_cache" ];
  fileSystems."/var".options = [ "subvol=@var" "rw" "noatime" "compress=zstd" "ssd" "space_cache" ];

  # Set your time zone.
  time.timeZone = meta.timeZone;

  nixpkgs.config.allowUnfree = true;

  #nixpkgs.config.packageOverrides = pkgs:
  #  { gnupg = pkgs.gnupg.override { pinentry = pkgs.pinentry_gnome; };
  #};

  nixpkgs.overlays = [
    (import ./overlays/packages.nix)
  ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = import ./system-packages.nix pkgs;

  environment.shellInit = ''
    gpg-connect-agent /bye
    export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
  '';

  environment.shells = [ pkgs.bashInteractive pkgs.zsh pkgs.fish ];

  # Enable docker
  virtualisation.docker.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.bash.enableCompletion = true;
  # programs.mtr.enable = true;
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

  security.pam.services.swaylock = {
    text = ''
      auth include login
    '';
  };

 # services.hydra.enable = true;
 # services.hydra.hydraURL = http://localhost:8910;
 # services.hydra.notificationSender = "hydra@insane.se";
 # services.postgresql.enable = true;
 # services.postgresql.authentication = lib.mkForce ''
 #   # Generated file; do not edit!
 #   # TYPE  DATABASE        USER            ADDRESS                 METHOD
 #   local   all             all                                     trust
 #   host    all             all             127.0.0.1/32            trust
 #   host    all             all             ::1/128                 trust
 # '';

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Enable autorandr (automatic monitor detection)
  # services.autorandr.enable = true;

  users.defaultUserShell = pkgs.fish;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.printing.drivers = [ pkgs.gutenprint ];

  # Disable suspend on lid close
  # services.logind.lidSwitch = "ignore";

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio = {
    enable = true;
    package = pkgs.pulseaudioFull;
  };
  hardware.bluetooth.enable = true;


  services.dbus.packages = with pkgs; [ gnome2.GConf gnome3.gcr gnome3.dconf ];
  services.udev.packages = with pkgs; [ gnome3.gnome-settings-daemon ];
  environment.pathsToLink = [ "/etc/gconf" ];

  powerManagement.cpuFreqGovernor = "powersave";
  powerManagement.enable = true;
  powerManagement.powertop.enable = true;
  powerManagement.resumeCommands = ''
    ${pkgs.killall}/bin/killall -9 gpg-agent
  '';

  services.syncthing = {
    enable = true;
    user = "${meta.userName}";
    dataDir = "/home/${meta.userName}/.config/syncthing";
  };

  # Don't hurt my eyes at night
  services.redshift = {
    package = pkgs.redshiftwl;
    enable = true;
    latitude = "59.344";
    longitude = "18.045";
    temperature.day = 6500;
    temperature.night = 2700;
  };

  # Hide the cursor unless moving it around
  services.xbanish.enable = true;

  # Enable upower
  services.upower.enable = true;

  # Enable the X11 windowing system.
  # services.xserver.enable = true;
  # services.xserver.layout = meta.xserverLayout;
  # services.xserver.xkbVariant = meta.xserverXkbVariant;
  # services.xserver.xkbModel = meta.xserverXkbModel;
  # services.xserver.xkbOptions = meta.xserverXkbOptions;

  # Video driver
  # services.xserver.videoDrivers = meta.videoDrivers or [ "ati" "cirrus" "intel" "vesa" "vmware" "modesetting" ];

  # Enable touchpad support.
  # services.xserver.libinput.enable = true;
  # services.xserver.libinput.naturalScrolling = true;
  # services.xserver.libinput.middleEmulation = true;
  # services.xserver.libinput.tapping = true;
  # services.xserver.libinput.disableWhileTyping = true;
  # services.xserver.inputClassSections = [ ''
  #   Identifier "mouse"
  #   Driver "libinput"
  #   MatchIsPointer "on"
  #   Option "NaturalScrolling" "true"
  #   Option "Tapping" "off"
  # '' ];

  # Enable the KDE Desktop Environment.
  # services.xserver.displayManager.sddm.enable = true;
  # services.xserver.desktopManager.plasma5.enable = true;

  # gdm starts pulseaudio which interferes with bluetooth and user pulseaudio
  # don't know how to disable that through nix yet - and why even use gdm when
  # I'm not that fond of gnome3 anyway.
  # services.xserver.displayManager.gdm.enable = true;
  # services.xserver.displayManager.lightdm.enable = true;
  # services.xserver.displayManager.lightdm.background = meta.dmBackground;
  # services.xserver.displayManager.lightdm.greeters.gtk.theme.name = "Adapta-Nokto";
  # services.xserver.displayManager.lightdm.greeters.gtk.theme.package = pkgs.adapta-gtk-theme;
  # services.xserver.displayManager.lightdm.greeters.gtk.indicators = [ "~spacer" "~spacer" "~session" "~power" ];
  # services.xserver.displayManager.lightdm.greeters.gtk.extraConfig = meta.lightdmExtraConfig;

  # services.compton.enable = true;
  # services.compton.fade = true;
  # services.compton.backend = "glx";
  # services.compton.vSync = "opengl-swc";
  # services.compton.fadeDelta = 6;
  # services.compton.opacityRules = [ "0:_NET_WM_STATE@:32a *= '_NET_WM_STATE_HIDDEN'" ];
  # services.compton.shadowExclude = [ "name = 'Screenshot'" "class_g = 'slop'" "_NET_WM_STATE@:32a *= '_NET_WM_STATE_HIDDEN'" ] ;
  # services.compton.fadeSteps = [ "0.08" "0.08" ];
  # services.compton.inactiveOpacity = "0.89";
  # services.compton.extraOptions = ''
  #   inactive-dim = 0.3;
  #   blur-background = true;
  #   blur-background-frame = true;
  #   blur-background-fixed = false;
  #   blur-background-exclude = [ "window_type = 'dock'", "window_type = 'desktop'", "class_g = 'slop'", "name = 'Screenshot'" ];
  #   no-fading-openclose = false; # Avoid fade windows in/out when opening/closing.
  #   mark-wmmin-focused = true;
  #   mark-ovredir-focused = true;
  #   detect-rounded-corners = true;
  #   unredir-if-possible = true;
  #   detect-transient = true;
  #   glx-no-stencil = true;
  #   glx-no-rebind-pixmap = true;
  # '';

  # services.xserver.windowManager.i3.enable = true;
  # services.xserver.windowManager.i3.extraSessionCommands = ''
  #   export QT_STYLE_OVERRIDE=gtk
  #   export VISUAL=ed
  #   export EDITOR=$VISUAL
  #   export PROJECTS=~/Development
  #   if [ -e .config/syncthing/config.xml ]; then
  #      SYNCTHING_API_KEY=$(cat .config/syncthing/config.xml | grep apikey | awk -F">|</" '{print $2}')
  #      if [ "$SYNCTHING_API_KEY" != "" ]; then
  #         export SYNCTHING_API_KEY
  #      fi
  #   fi
  #   # Load X resources.
  #   if [ -e $HOME/.Xresources ]; then
  #       ${pkgs.xorg.xrdb}/bin/xrdb -merge $HOME/.Xresources
  #   fi
  # '';


  # want to run this not on an OnCalendar spec but rather on certain system events
  # otherwise we could have used just the "startAt" field of service.
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
    #environment = {
    #  DISPLAY = ":0";
    #  XAUTHORITY="/home/${meta.userName}/.Xauthority";
    #};
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

  #systemd.user.services.dropbox = rec {
  #  description = "Dropbox service";
  #  enable = true;
  #  environment = {
  #    DISPLAY = ":0";
  #    XAUTHORITY="/home/%U/.Xauthority";
  #  };
  #  script = ''
  #    ${pkgs.dropbox}/bin/dropbox
  #  '';
  #  wantedBy = [ "default.target" ];
  #};

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

  # Gnome keyring yes please - also see the service
  security.pam.services."${meta.userName}".enableGnomeKeyring = true;

  # Make sure the only way to add users/groups is to change this file
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

  system.activationScripts = {
    linkShared = pkgs.lib.stringAfter [ "users" ]
    ''
      rm -rf /home/shared
      ln -s /etc/nixos/shared /home/shared
    '';
    linkIcons = pkgs.lib.stringAfter [ "users" ]
    ''
      mkdir -p /var/lib/AccountsService
      rm -rf /var/lib/AccountsService/icons
      ln -s /etc/nixos/user-icons /var/lib/AccountsService/icons
    '';
    accountsSvcUser = pkgs.lib.stringAfter [ "users" ]
    ''
      cat <<EOF> /var/lib/AccountsService/users/${meta.userName}
      [User]
      XSession=none+i3
      Icon=${meta.userIcon}
      SystemAccount=false
      EOF
    '';
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "18.03";

}
