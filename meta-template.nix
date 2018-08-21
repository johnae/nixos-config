{
  hostName = "<HOSTNAME>";
  consoleFont = "Lat2-Terminus16";
  consoleKeyMap = "sv-latin1";
  defaultLocale = "en_US.UTF-8";
  timeZone = "Europe/Stockholm";
  xserverLayout = "se";
  xserverXkbVariant = "mac";
  xserverXkbModel = "pc105";
  xserverXkbOptions = "ctrl:nocaps,lv3:lalt_switch,compose:ralt,lv3:ralt_alt";
  lightdmExtraConfig = "";
  dmBackground = "/home/shared/backgrounds/dark-mountains.png";
  userName = "john";
  userDescription = "John Axel Eriksson";
  userIcon = "/var/lib/AccountsService/icons/earth.png";
  userPassword = "<PASSWORD>"; # mkpasswd -m sha-512 -s <<< the-password-here
  backupDestination = "user@some.example.com";
  backupPort = "12345";
  backupSshKey = "/path/to/id_rsa";
  knownHosts = [ { hostNames = [ "[some.example.com]:12345" "[10.10.10.11]:12345" ]; publicKey = "ssh-rsa AAAAB3NzaC1yc2VeryLongKeyHereFollowsAllTheWayUntilTheEnd"; } ];
  kernelParams = []; ## for example [ "btusb.enable_auto_suspend=0" ] is useful on some machines where bluetooth would otherwise die on sleep and never come back up;
  # videoDrivers = [ "modesetting" ];
}
