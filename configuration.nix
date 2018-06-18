# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

# For machine specific stuff
let
  meta = import ./meta.nix;

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

  hardware.cpu.intel.updateMicrocode = true;
  hardware.opengl.enable = true;
  hardware.opengl.driSupport = true;

  networking.hostName = meta.hostName;
  networking.extraHosts = "127.0.1.1 ${meta.hostName}";
  networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Select internationalisation properties.
  i18n = {
    consoleFont = meta.consoleFont;
    consoleKeyMap = "sv-latin1";
    defaultLocale = "en_US.UTF-8";
  };

  # additional fs options
  fileSystems."/".options = [ "subvol=@" "rw" "noatime" "compress=zstd" "ssd" "space_cache" ];
  fileSystems."/home".options = [ "subvol=@home" "rw" "noatime" "compress=zstd" "ssd" "space_cache" ];
  fileSystems."/var".options = [ "subvol=@var" "rw" "noatime" "compress=zstd" "ssd" "space_cache" ];

  # Set your time zone.
  time.timeZone = "Europe/Stockholm";

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

  environment.shells = [ pkgs.bashInteractive pkgs.zsh ];

  # Enable docker
  virtualisation.docker.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.bash.enableCompletion = true;
  # programs.mtr.enable = true;
  programs.gnupg.agent = { enable = true; enableSSHSupport = true; };

  services.pcscd.enable = true;
  services.cron.enable = true;

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  users.defaultUserShell = pkgs.zsh;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.printing.drivers = [ pkgs.gutenprint ];

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio = {
    enable = true;
    package = pkgs.pulseaudioFull;
  };
  hardware.bluetooth.enable = true;

  services.dbus.packages = [ pkgs.gnome3.gconf pkgs.gnome3.gcr ];
  environment.pathsToLink = [ "/etc/gconf" ];

  powerManagement.cpuFreqGovernor = "powersave";

  services.redshift = {
    enable = true;
    latitude = "43.365";
    longitude = "-8.41";
    temperature.day = 6500;
    temperature.night = 2700;
  };

  services.syncthing = {
    enable = true;
    user = "john";
    dataDir = "/home/john/.config/syncthing";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.layout = "se";
  services.xserver.xkbVariant = "mac";
  services.xserver.xkbModel = "pc105";
  services.xserver.xkbOptions = "ctrl:nocaps,lv3:lalt_switch,compose:ralt,lv3:ralt_alt";

  # Enable touchpad support.
  services.xserver.libinput.enable = true;
  services.xserver.libinput.naturalScrolling = true;
  services.xserver.libinput.middleEmulation = true;
  services.xserver.libinput.tapping = true;

  # Enable the KDE Desktop Environment.
  # services.xserver.displayManager.sddm.enable = true;
  # services.xserver.desktopManager.plasma5.enable = true;

  # gdm starts pulseaudio which interferes with bluetooth and user pulseaudio
  # don't know how to disable that through nix yet - and why even use gdm when
  # I'm not that fond of gnome3 anyway.
  # services.xserver.displayManager.gdm.enable = true;
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.displayManager.lightdm.background = meta.dmBackground;
  services.xserver.displayManager.lightdm.greeters.gtk.theme.name = "Adapta-Nokto";
  services.xserver.displayManager.lightdm.greeters.gtk.theme.package = pkgs.adapta-gtk-theme;
  services.xserver.displayManager.lightdm.greeters.gtk.extraConfig = ''
    indicators=~spacer;~spacer;~session;~power
    ${meta.lightdmExtraConfig}
  '';

  services.xserver.windowManager.i3.enable = true;
  services.xserver.windowManager.i3.extraSessionCommands = ''
     export PATH=$HOME/Local/bin:$PATH
     if [ -e $HOME/.defaultrc ]; then
       source $HOME/.defaultrc
     fi
     if [ -e $HOME/.localrc ]; then
       source $HOME/.localrc
     fi
     if [ -e $HOME/.profile.d/zsh/path.zsh ]; then
       source $HOME/.profile.d/zsh/path.zsh
     fi
     if [ -e $HOME/.profile.d/zsh/aliases.zsh ]; then
       source $HOME/.profile.d/zsh/aliases.zsh
     fi
     if [ -e $HOME/.profile.d/zsh/fzf-theme.zsh ]; then
       source $HOME/.profile.d/zsh/fzf-theme.zsh
     fi
     # Load X defaults.
     if [ -e $HOME/.Xresources-${meta.hostName} ]; then
         ${pkgs.xorg.xrdb}/bin/xrdb -merge ~/.Xresources-${meta.hostName}
     fi
     if [ -e $HOME/.Xdefaults-${meta.hostName} ]; then
         ${pkgs.xorg.xrdb}/bin/xrdb -merge ~/.Xdefaults-${meta.hostName}
     fi
  '';

  fonts.fonts = with pkgs; [
     google-fonts
     source-code-pro
     system-san-francisco-font
     font-awesome_4
     font-droid
     powerline-fonts
     roboto
  ];

  # Define a user account. Don't forget to set a password with ‘passwd’.

  # Make sure the only way to add users/groups is to change this file
  users.mutableUsers = false;

  users.groups.john.gid = 1337;
  users.extraUsers.john = {
    isNormalUser = true;
    uid = 1337;
    extraGroups = [ "wheel" "docker" "video" "audio" ];
    description = "John Axel Eriksson";
    shell = pkgs.zsh;
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
      cat <<EOF> /var/lib/AccountsService/users/john
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
  # system.stateVersion = "18.03"; # Did you read the comment? old name
  system.nixos.stateVersion = "18.03"; # Did you read the comment? new name (after 18.03)

}
